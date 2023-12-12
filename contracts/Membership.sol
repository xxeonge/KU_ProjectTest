// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import 'hardhat/console.sol';

// 인터페이스: ERC20 토큰 전송 함수 사용
interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

/**
 * @title Membership
 * @dev 사용자 데이터베이스 및 주차 관리를 위한 스마트 계약
 */
contract Membership {
    // 계정 주소에 대한 주차번호 매핑
    mapping(address => uint256) private parkingNumbers;
    // 계정 주소에 대한 가입비 낸 여부 매핑
    mapping(address => bool) private hasPaidMembershipFee;
    // 계정 주소에 대한 입차 타임스탬프 매핑
    mapping(address => uint256) private getTimestamps;
    address private permission;
    // 주차비 토큰 주소
    address private feeToken;
    // 가입비 (단위: FEE)
    uint256 private membershipFee = 10; 

    // 이벤트 정의
    event AccountRegistered(address indexed userAddress, uint256 parkingNumber);
    event EntryRecorded(address indexed userAddress, uint256 entryTimestamps);
    event ExitRecorded(address indexed userAddress, uint256 exitTimestamp, uint256 fee);

    // 컨트랙트 생성자: 토큰 주소 초기화
    constructor(address _token) {
        permission = msg.sender;
        feeToken = _token;
    }

    /**
     * @dev 회원가입 함수
     * @param _parkingNumber 사용자의 주차번호
     */
    function registerUser(uint256 _parkingNumber) external {
         // _parkingNumber = 0, 트랜잭션 실패
        require(_parkingNumber != 0, "Parking number must not be zero");
        
        // 가입비 전송
        IERC20(feeToken).transferFrom(msg.sender, address(this), membershipFee);

        // 주차번호 및 가입비 낸 여부 등록
        parkingNumbers[msg.sender] = _parkingNumber;
        hasPaidMembershipFee[msg.sender] = true;

        emit AccountRegistered(msg.sender, _parkingNumber);
    }

    /**
     * @dev 멤버 여부 확인 함수
     * @return 사용자가 멤버인지 여부 (true: 멤버, false: 비멤버)ㅋㅌ
     */
    function checkUser() public view returns (bool) {
        // 주차번호와 가입비 낸 여부 확인
        return parkingNumbers[msg.sender] != 0 && hasPaidMembershipFee[msg.sender];
    }

    /**
     * @dev 멤버 인증 함수
     * @param _parkingNumber 사용자의 주차번호
     * @return 인증 여부 (true: 인증 성공, false: 인증 실패)
     */
    function authenticateUser(uint256 _parkingNumber) external view returns (bool) {
        return parkingNumbers[msg.sender] == _parkingNumber;
    }

    /**
     * @dev 입차 타임스탬프 기록 함수
     */
    function entryTimestamp() external {
        uint256 timestamp = block.timestamp;
        getTimestamps[msg.sender] = timestamp;
        emit EntryRecorded(msg.sender, timestamp);
    }

    /**
     * @dev 출차 타임스탬프 반환
     * @return 현재 블록 타임스탬프
     */
    function getExitTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev 주차비 계산 및 결제 함수
     */
    function exitFee() external{
        require(getTimestamps[msg.sender] != 0, "No entry record found");

         // 입차 기록 초기화
        uint256 entryRec = getTimestamps[msg.sender];
        getTimestamps[msg.sender] = 0;
        
        // 주차 시간 계산
        uint256 parkingDuration = block.timestamp - entryRec;
        uint256 fee;
        
        // 멤버인 경우, 주차 시간 3시간 이하일 경우 주차비 0, 추가 주차 시간 계산
        if (checkUser()) {
            if (parkingDuration > 3 hours) {
                uint256 memberTime = (parkingDuration - 3 hours) / 10 minutes;
                fee = memberTime * 1000;
            }
        }
        // 멤버가 아닐 경우
        else {
            uint256 notmemberTime = parkingDuration / 10 minutes;
            fee = notmemberTime * 1000;
        }

        if (fee > 0) {
            // 주차비 컨트랙트로 전송
            console.log(fee * 10 ** 18);
            IERC20(feeToken).transferFrom(msg.sender, address(this), fee * 10 ** 18);
        }  
            // 출차 기록 타임스탬프 발생
            emit ExitRecorded(msg.sender, block.timestamp, fee);
     }

    /**
     * @dev 사용자 입차 시간 확인 함수
     * @return 입차한 타임스탬프
     */
    function getEntry() public view returns (uint256) {
        return getTimestamps[msg.sender];
    }

    /**
     * @dev 주차비 토큰 주소 확인 함수
     * @return 주차비로 사용되는 토큰 주소
     */
    function getFeeToken() public view returns (address) {
        return feeToken;
    }

   /**
     * @dev 멤버십 가입비 조회 함수
     * @return 가입비 (단위: FEE)
     */
    function getMembershipFee() public view returns (uint256) {
        return membershipFee;
    }
}
