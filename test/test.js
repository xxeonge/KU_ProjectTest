const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('Membership Contract', function () {
  let Membership;
  let owner;
  let user;
  let feeToken;

  const membershipFee = 10;

 
  it('init', async function () {
    [owner, user] = await ethers.getSigners();
    feeToken = await (await ethers.getContractFactory('FeeToken')).deploy(owner.address);   
    Membership = await (await ethers.getContractFactory('Membership')).deploy(await feeToken.getAddress());
  
    //  function mint(address to, uint256 amount) public onlyOwner
    await feeToken.mint(user.address, ethers.parseEther('1000000'));
    
  });

  it('Should register user and checkuser', async function () {
    const parkingNumber = 123;
    await feeToken.connect(user).approve(Membership, membershipFee);
    await Membership.connect(user).registerUser(parkingNumber);

    const isMember = await Membership.connect(user).checkUser();
    expect(isMember).to.equal(true);
  });

  it('should authenticate the user with the correct parking number', async function () {
    const isAuthenticated = await Membership.connect(user).authenticateUser(123);
    expect(isAuthenticated).to.equal(true);
  })

  it('Should record entry and exit timestamps', async function () {
    // Record entry timestamp
    await Membership.connect(user).entryTimestamp(); // 입차 시간
    const entryTimestamp = await Membership.connect(user).getEntry();
    expect(entryTimestamp).to.not.equal(0);
  });

  it('Should calculate and pay exit fee', async function () {
    const initialBalance = await feeToken.balanceOf(user.address);

    // Record entry timestamp
    await Membership.connect(user).entryTimestamp();
    
    const parkingDuration = 4 * 60 * 60; // 4 hours

    // Increase time to simulate parking duration
    await ethers.provider.send('evm_increaseTime', [parkingDuration]);
    
    // Record exit timestamp and pay exit fee
    await feeToken.connect(user).approve(await Membership.getAddress(), ethers.parseEther('1000000'));
    
    await Membership.connect(user).exitFee();

    const finalBalance = await feeToken.balanceOf(user.address);

    const expectedFee = ((parkingDuration - (3 * 3600)) / 600 * 1000);
    
    expect(initialBalance).to.equal(finalBalance + ethers.parseEther(expectedFee.toString()));
    
  });
});