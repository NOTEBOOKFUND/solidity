pragma solidity =0.7.6;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
contract NBGame {
    using SafeMath for uint;
    event ev_join(address indexed addr, uint64 playId, uint64 pre,uint64 next, address token, uint256 _value, uint256 _fee, uint64 timestamp);
    event ev_out(address indexed addr,  uint64 playId, uint64 pre,uint64 next, address token, uint256 _value, uint64 timestamp);
    event ev_profit(address indexed addr, uint64 playId, address token, uint256 _value, uint8 tokenType, uint64 timestamp);
    event ev_vip_profit(address indexed addr, uint64 playId, address token, uint256 _value, uint256 _usdtvalue, uint8 tokenType, uint64 timestamp);
    event ev_nbs_rate(address indexed addr, uint256 oldrate, uint256 newrate);
    event ev_issue(address indexed addr,  uint64 playcnt, uint256 total, uint64 timestamp);
    event ev_settle_profit(address indexed addr, address token, uint64 playcnt, uint64 timestamp);
    event ev_opex_withdraw(address indexed addr,  uint8 withdrawtype, uint256 nbs, uint256 usdt, uint64 timestamp);
    address private owner = 0x2B064a49F4F445CCDf99cc41737B7e599Fc03762;
    address public op_addr = 0x877Da52EA00122503eB83CC96af6ca9866d91A50;
    address public fund_addr = 0x217c9321BFCc268e9a3CeFCcf7AB78e9a7A89576; 
    address public team_addr = 0x7E207D26a9942eB6Cb406be8a711D21338C5F258; 
    address public investor_addr = 0x22E9c8321A278C74416cA42d88AA527071F33590;
    struct TokenInfo {
        uint256 num;
        uint256 profit;
        uint8 tokentype;
        uint64 starttime;
        uint64 next;
        uint64 pre;
    }
    struct TotalInfo {
        uint256 num;
        uint256 supply;
        uint256 fee;
        uint256 opex_fund; 
        uint256 opex_team; 
        uint256 opex_investor; 
        uint8 tokentype;
        uint64 starttime;
    }
    struct Player {
        uint64  create_timestamp;
    }
    uint64 public deploy_time;
    uint64 public deploy_block_num;
    uint64 public sys_start_time = 0; 
    uint64 private month_sec = 2592000; 
    uint64 private day5_sec = 432000; 
    uint64 private year_sec = 31536000; 
    int8 private STD_IDX_END = 8;
    int8 private NBK_LP_IDX = 10;
    int8 private NBK_IDX = 12;
    int8 private NBS_IDX = 13;
    Player[] public players;
    mapping (address => uint64) public playerIdx;
    mapping (uint64 => address) public idToAddr;
    mapping (uint64 => mapping(address => TokenInfo)) public pledge_token;
    mapping (uint64 => mapping(address => TokenInfo)) public vip_token;
    mapping (address => TotalInfo) public xtokens;
    mapping (address => uint) public tokenRate;
    address private WHT_ADDR=0x5545153CCFcA01fbd7Dd11C0b23ba694D9509A6F;
    address private USDT_ADDR=0xa71EdC38d189767582C38A3145b5873052c3e47a;
    address private HUSD_ADDR=0x0298c2b32eaE4da002a15f36fdf7615BEa3DA047;
    address private HBTC_ADDR=0x66a79D23E58475D2738179Ca52cd0b41d73f0BEa;
    address private ETH_ADDR=0x64FF637fB478863B7468bc97D30a5bF3A428a1fD;
    address private MDX_ADDR=0x25D2e80cB6B86881Fd7e07dd263Fb79f4AbE033c;
    address private TPT_ADDR=0x9ef1918a9beE17054B35108bD3E2665e2Af1Bb1b;
    address private BXH_ADDR=0xcBD6Cb9243d8e3381Fea611EF023e17D1B7AeDF0;
    address public NBK_ADDR = 0x6EfCE2817dFe08C37f6E6BC4969d4763c4ba9434;
    address public NBS_ADDR = 0x1fd0FBcdc30dF6f84E68de16Fa4E08476CEae3BB;
    address public NBK_USDT_PAIR_ADDR = 0x449555F68934a1D02d2d9c71ffAa78Bbd46801b1;
    address public NBK_HBTC_PAIR_ADDR=0xE6f3b8F59bdE38DA5544e8ACaB9C4B5B7D4fF1F1;
    address public NBS_USDT_PAIR_ADDR = 0xa1332Ec01BD3fd727E72Bd76Cdd64852a60EfE39;
    address public NBS_HBTC_PAIR_ADDR=0x81fe32f939E298bD44Eb977bB8aC506f80894696;
    address[] private Init_Token_Addr = [WHT_ADDR, USDT_ADDR, HUSD_ADDR,HBTC_ADDR,ETH_ADDR,MDX_ADDR,TPT_ADDR,BXH_ADDR,
    NBK_USDT_PAIR_ADDR,NBK_HBTC_PAIR_ADDR,
    NBS_USDT_PAIR_ADDR,NBS_HBTC_PAIR_ADDR,
    NBK_ADDR,
    NBS_ADDR
   ];
    uint64[] public last_token_player = [1, 1, 1,1,1,1,1,1,1,1,1,1,1,1];
    uint256 public vip_usdt_num; 
    uint256[] private MONTH_LP_RATE = [49870386993816078, 41558655828180065, 34632213190150054, 28860177658458378];
    modifier onlyAdmin() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyOperator() {
        require(msg.sender == op_addr);
        _;
    }
    function set_op_addr(address opAddr) external onlyAdmin{
        op_addr = opAddr;
    }
    function set_withdraw_addr(address fundaddr, address teamaddr, address investoraddr) external onlyAdmin{
        fund_addr = fundaddr; 
        team_addr = teamaddr; 
        investor_addr = investoraddr;
    }
    function fund_withdraw() external {
        require(msg.sender == fund_addr);
        int8 idx;
        uint val;
        uint nbs;
        TotalInfo storage aInfo;
        address token;
        settle_opex();
        for(idx = STD_IDX_END; idx < NBK_IDX; idx++){
            token = Init_Token_Addr[uint(idx)];
            aInfo = xtokens[token];
            nbs = nbs.add(aInfo.opex_fund);
            aInfo.opex_fund = 0;
        }
        if(nbs > 0){
            IERC20(NBS_ADDR).transfer(fund_addr, nbs); 
        }
        for(idx = 0; idx < STD_IDX_END; idx++){
            token = Init_Token_Addr[uint(idx)];
            aInfo = xtokens[token];
            if(aInfo.fee > 0){
                val = aInfo.fee;
                aInfo.fee = 0;
                IERC20(token).transfer(fund_addr, val); 
            }
        }
        if(vip_usdt_num > 0) {
            val = vip_usdt_num;
            vip_usdt_num = 0;
            IERC20(USDT_ADDR).transfer(fund_addr, val); 
        }
        emit ev_opex_withdraw(msg.sender, 1, nbs, val, uint64(block.timestamp));
    }
    function team_withdraw() external {
        require(msg.sender == team_addr);
        int8 idx;
        uint val;
        TotalInfo storage aInfo;
        address token;
        settle_opex();
        for(idx = STD_IDX_END; idx < NBK_IDX; idx++){
            token = Init_Token_Addr[uint(idx)];
            aInfo = xtokens[token];
            val = val.add(aInfo.opex_team);
            aInfo.opex_team = 0;
        }
        if(val > 0){
            IERC20(NBS_ADDR).transfer(team_addr, val); 
            emit ev_opex_withdraw(msg.sender, 2, val, 0, uint64(block.timestamp));
        }
    }
    function investor_withdraw() external {
        require(msg.sender == investor_addr);
        int8 idx;
        uint val;
        TotalInfo storage aInfo;
        address token;
        settle_opex();
        for(idx = STD_IDX_END; idx < NBK_IDX; idx++){
            token = Init_Token_Addr[uint(idx)];
            aInfo = xtokens[token];
            val = val.add(aInfo.opex_investor);
            aInfo.opex_investor = 0;
        }
        if(val > 0){
            IERC20(NBS_ADDR).transfer(investor_addr, val); 
            emit ev_opex_withdraw(msg.sender, 3, val, 0, uint64(block.timestamp));
        }
    }
    function settle_opex() internal {
        uint profit;
        uint opex;
        uint opex_investor;
        uint opex_team;
        address token;
        TotalInfo storage aInfo;
        for(int8 idx = STD_IDX_END; idx < NBK_IDX; idx++){
            token = Init_Token_Addr[uint(idx)];
            aInfo = xtokens[token];
            if(aInfo.num > 0){
                (profit,opex) = calc_profit(aInfo.num, aInfo.starttime, token);
                (opex, opex_team, opex_investor) = calc_opex(opex);
                aInfo.opex_team=aInfo.opex_team.add(opex_team); 
                aInfo.opex_investor=aInfo.opex_investor.add(opex_investor); 
                aInfo.opex_fund=aInfo.opex_fund.add(opex); 
                aInfo.starttime = uint64(block.timestamp);
            }
        }
    }
    function set_start_time(uint64 starttime) external onlyOperator{
        require(starttime == 0 || starttime >= deploy_time);
        sys_start_time = starttime;
    }
    function issue_nbk(uint64[] memory playerlist, uint[] memory nums) external onlyOperator {
        require(playerlist.length > 0, "playerlist empty");
        require(playerlist.length == nums.length, "param error");
        uint64 playerId;
        uint total;
        TokenInfo storage tInfo;
        for(uint i = 0; i < playerlist.length; i++) {
            playerId = playerlist[i];
            if(playerId < 1 || playerId >= players.length) continue;
            tInfo = vip_token[playerId][NBS_ADDR];
            tInfo.profit = tInfo.profit.add(nums[i]); 
            total += nums[i];
        }
        TotalInfo storage aInfo = xtokens[NBS_ADDR];
        aInfo.supply = aInfo.supply.add(total);  
        emit ev_issue(msg.sender, uint64(playerlist.length), total, uint64(block.timestamp));
    }
    function settle_profit(uint64[] memory playerlist, address token) external onlyOperator {
        require(playerlist.length > 0, "playerlist empty");
        uint64 playerId;
        uint64 timestamp = uint64(block.timestamp);
        uint profit;
        uint opex;
        TokenInfo storage tInfo;
        for(uint i = 0; i < playerlist.length; i++) {
            playerId = playerlist[i];
            tInfo = pledge_token[playerId][token];
            if(tInfo.num > 0){
                (profit,opex) = calc_profit(tInfo.num, tInfo.starttime, token);
                tInfo.profit = tInfo.profit.add(profit); 
                tInfo.starttime = timestamp;
            }
        }
        emit ev_settle_profit(msg.sender, token, uint64(playerlist.length), timestamp);
    }
    constructor() public {
        deploy_time = uint64(block.timestamp);
        deploy_block_num = uint64(block.number);
        Player memory _player = Player({
            create_timestamp: deploy_time
        });
        players.push(_player);
        players.push(_player);
        uint64 playerId = uint64(players.length - 1);
        playerIdx[owner] = playerId;
        idToAddr[playerId] = owner;
        emit ev_join(owner, playerId, 0, 0, WHT_ADDR, 0, 0, deploy_time); 
        tokenRate[WHT_ADDR] = 9259259259259300; 
        tokenRate[USDT_ADDR] = 9259259259259300; 
        tokenRate[HUSD_ADDR] = 9259259259259300; 
        tokenRate[HBTC_ADDR] = 9259259259259300; 
        tokenRate[ETH_ADDR] = 9259259259259300; 
        tokenRate[MDX_ADDR] = 4629629629629600; 
        tokenRate[TPT_ADDR] = 3472222222222222; 
        tokenRate[BXH_ADDR] = 3472222222222222; 
        tokenRate[NBK_ADDR] = 0; 
        tokenRate[NBS_ADDR] = 0; 
        tokenRate[NBK_USDT_PAIR_ADDR] = 35; 
        tokenRate[NBK_HBTC_PAIR_ADDR] = 35; 
        tokenRate[NBS_USDT_PAIR_ADDR] = 15; 
        tokenRate[NBS_HBTC_PAIR_ADDR] = 15; 
        TotalInfo storage aInfo;
        int8 i;
        for(uint idx = 0; idx < Init_Token_Addr.length; idx++){
            aInfo = xtokens[Init_Token_Addr[idx]];
            i = int8(idx);
            if ( i < STD_IDX_END){ 
                aInfo.tokentype = 1; 
            }else if (i >= STD_IDX_END && i < NBK_IDX){
                aInfo.tokentype = 2; 
            }
            else if (i == NBS_IDX){
                aInfo.tokentype = 1; 
            }
        }
    }
    function join(address token, uint256 value) public {
        int8 i = get_token_index(token);
        require(i >= 0, "invalid token");
        require(IERC20(token).transferFrom(msg.sender, address(this), value));  
        require(value > 10000000000, "value too small");
        uint64 playerId = playerIdx[msg.sender];
        uint64 timestamp = uint64(block.timestamp);
        Player storage p;
        TokenInfo storage tInfo;
        if(playerId > 0){ 
            p = players[playerId];
        } else { 
            playerId = uint64(players.length);
            Player memory _player = Player({
                create_timestamp: timestamp
            });
            players.push(_player);
            playerIdx[msg.sender] = playerId;
            idToAddr[playerId] = msg.sender;
            p=players[playerId];
        }
        uint256 fee;
        TotalInfo storage aInfo = xtokens[token];
        if ( i < STD_IDX_END){ 
            tInfo = pledge_token[playerId][token];
            tInfo.tokentype = 1; 
            fee = value.mul(4).div(100);
            value = value.sub(fee); 
            aInfo.fee=aInfo.fee.add(fee);  
        }else if (i >= STD_IDX_END && i < NBK_IDX){
            tInfo = pledge_token[playerId][token];
            tInfo.tokentype = 2; 
        }
        else if (i == NBS_IDX){
            tInfo = vip_token[playerId][token];
            tInfo.tokentype = 1; 
        }
       do_join_profit(tInfo, playerId, uint(i), value);
       emit ev_join(msg.sender, playerId, tInfo.pre, tInfo.next, token, value, fee, timestamp); 
    }
    function do_join_profit(TokenInfo storage tInfo, uint64 playerId, uint tokenidx, uint256 value) internal {
        uint profit;
        uint opex;
        uint opex_team;
        uint opex_investor;
        uint64 timestamp = uint64(block.timestamp);
        address token = Init_Token_Addr[tokenidx];
        if(tInfo.num > 0) {
            (profit, opex) = calc_profit(tInfo.num, tInfo.starttime, token);
            tInfo.profit = tInfo.profit.add(profit);
            tInfo.starttime = timestamp;
            tInfo.num = tInfo.num.add(value);
        }else{
            tInfo.num = value;
            tInfo.starttime = timestamp; 
        }
        do_token_lian(tInfo, playerId, tokenidx);
        TotalInfo storage aInfo = xtokens[token];
        (profit, opex) = calc_profit(aInfo.num, aInfo.starttime, token);
        aInfo.supply=aInfo.supply.add(profit); 
        aInfo.num=aInfo.num.add(value); 
        (opex, opex_team, opex_investor) = calc_opex(opex);
        aInfo.opex_team=aInfo.opex_team.add(opex_team); 
        aInfo.opex_investor=aInfo.opex_investor.add(opex_investor); 
        aInfo.opex_fund=aInfo.opex_fund.add(opex); 
        aInfo.starttime = timestamp;
    }
    function do_token_lian(TokenInfo storage tInfo, uint64 playerId, uint idx) internal{
        address token = Init_Token_Addr[idx];
        TokenInfo storage info = tInfo;
        if(tInfo.num > 10000000000) {
            if(tInfo.pre == 0 && playerId > 1 && last_token_player[idx] != playerId){
                pledge_token[last_token_player[idx]][token].next = playerId;
                tInfo.pre = last_token_player[idx];
                last_token_player[idx] = playerId;
            }
        }else{
            if(tInfo.pre > 0) {
                pledge_token[tInfo.pre][token].next = tInfo.next;
                if(last_token_player[idx] == playerId) last_token_player[idx] = tInfo.pre;
                info = pledge_token[tInfo.pre][token];
            }
            if(tInfo.next > 0){
                pledge_token[tInfo.next][token].pre = tInfo.pre;
                info = pledge_token[tInfo.next][token];
            }
            tInfo.pre = 0;
            tInfo.next = 0;
        }
        uint64 timestamp = uint64(block.timestamp);
        uint profit;
        uint opex;
        tInfo = info;
        for(idx=0; idx<12; idx++){
            if(info.pre < 1 || info.pre == playerId) break;
            info = pledge_token[info.pre][token];
            (profit, opex) = calc_profit(info.num, info.starttime, token);
            info.profit = info.profit.add(profit);
            info.starttime = timestamp;
        }
        info = tInfo;
        for( ; idx<12; idx++){
            if(info.next < 1 || info.next == playerId) break;
            info = pledge_token[info.next][token];
            (profit, opex) = calc_profit(info.num, info.starttime, token);
            info.profit = info.profit.add(profit);
            info.starttime = timestamp;
        }
    }
    function out(address token, uint256 value) public {
        int8 i = get_token_index(token);
        require(i >= 0, "invalid token");
        uint64 playerId = playerIdx[msg.sender];
        require(playerId>0, "invalid player");
        do_out(playerId, token, value, i); 
    }
    function do_out(uint64 playId, address token, uint256 value, int8 tokenidx) internal {
        uint profit;
        uint opex;
        TokenInfo storage tInfo;
        TotalInfo storage aInfo = xtokens[token];
        if (tokenidx != NBS_IDX ){
            tInfo = pledge_token[playId][token];
            require(tInfo.num>=value, "insufficient funds");
            (profit, opex) = calc_profit(tInfo.num, tInfo.starttime, token);
            tInfo.profit = tInfo.profit.add(profit); 
            tInfo.starttime = uint64(block.timestamp);
            tInfo.num = tInfo.num - value;
            (profit, opex) = calc_profit(aInfo.num, aInfo.starttime, token);
            aInfo.supply=aInfo.supply.add(profit);
            uint opex_investor;
            uint opex_team;
            (opex, opex_team, opex_investor) = calc_opex(opex);
            aInfo.opex_team=aInfo.opex_team.add(opex_team); 
            aInfo.opex_investor=aInfo.opex_investor.add(opex_investor); 
            aInfo.opex_fund=aInfo.opex_fund.add(opex); 
            aInfo.starttime = aInfo.starttime;
            IERC20(token).transfer(msg.sender, value);  
        } else {
            tInfo = vip_token[playId][token];
            require(tInfo.num>=value, "insufficient funds");
            tInfo.num =tInfo.num - value;
            IERC20(token).transfer(msg.sender, value);
        }
        do_token_lian(tInfo, playId, uint(tokenidx));
        aInfo.num = aInfo.num.sub(value);
        emit ev_out(msg.sender, playId, tInfo.pre, tInfo.next, token, value, tInfo.starttime); 
    }
    function draw_profit(address token) public {
        int8 i = get_token_index(token);
        require(i >= 0, "invalid token");
        require(i != NBS_IDX, "invalid token"); 
        uint64 playerId = playerIdx[msg.sender];
        require(playerId>0, "invalid player");
        uint profit;
        uint opex;
        TokenInfo storage tInfo = pledge_token[playerId][token];
        (profit,opex) = calc_profit(tInfo.num, tInfo.starttime, token);
        profit = tInfo.profit.add(profit); 
        tInfo.starttime = uint64(block.timestamp);
        require(profit>0, "insufficient funds");
        tInfo.profit = 0;
        if(tInfo.tokentype == 1) {
             IERC20(NBK_ADDR).transfer(msg.sender, profit);
        }else if(tInfo.tokentype == 2) {
             IERC20(NBS_ADDR).transfer(msg.sender, profit);
        }
        emit ev_profit(msg.sender, playerId, token, profit, tInfo.tokentype, tInfo.starttime); 
    }
    function draw_all_profit() public {
        uint64 playerId = playerIdx[msg.sender];
        require(playerId>0, "invalid player");
        uint totalNbk;
        uint totalNbs;
        uint profit;
        uint opex;
        uint nbsIdx = uint(NBS_IDX);
        address token;
        TokenInfo storage tInfo;
        for(uint idx = 0; idx < Init_Token_Addr.length; idx++){
            if (idx != nbsIdx) { 
                token = Init_Token_Addr[idx];
                tInfo = pledge_token[playerId][token];
                if(tInfo.num > 0){
                    (profit,opex) = calc_profit(tInfo.num, tInfo.starttime, token);
                    profit = tInfo.profit.add(profit); 
                    if(profit > 0) {
                        if(tInfo.tokentype == 1) {
                            totalNbk = totalNbk.add(profit);
                        }else if(tInfo.tokentype == 2) {
                            totalNbs = totalNbs.add(profit);
                        }
                        tInfo.profit = 0;
                        tInfo.starttime = uint64(block.timestamp);
                        emit ev_profit(msg.sender, playerId, token, profit, tInfo.tokentype, tInfo.starttime); 
                    }
                }
            }
        }
        if(totalNbk > 0) {
             IERC20(NBK_ADDR).transfer(msg.sender, totalNbk);
        }
        if(totalNbs > 0) {
             IERC20(NBS_ADDR).transfer(msg.sender, totalNbs);
        }
    }
    function draw_vip_profit(uint num) public {
        uint64 playerId = playerIdx[msg.sender];
        require(playerId>0, "invalid player");
        TokenInfo storage tInfo = vip_token[playerId][NBS_ADDR];
        require(tInfo.profit >= num, "insufficient funds");
        uint usdtVal = num / 2;
        vip_usdt_num = vip_usdt_num.add(usdtVal);
        require(IERC20(USDT_ADDR).transferFrom(msg.sender, address(this), usdtVal));  
        tInfo.profit = tInfo.profit - num;
        IERC20(NBK_ADDR).transfer(msg.sender, num);
        emit ev_vip_profit(msg.sender, playerId, NBS_ADDR, num, usdtVal, tInfo.tokentype, uint64(block.timestamp)); 
    }
    function get_token_index(address token) public view returns(int8) {
        for(uint i = 0; i < Init_Token_Addr.length; i++){
            if(token == Init_Token_Addr[i]) {
                 return int8(i);
            }
        }
        return -1;
    }   
    function calc_lp_profit(uint num, uint starttime, uint nowtime, address token) internal view returns(uint profit,uint opex) {
        uint monx = (starttime - sys_start_time) / month_sec; 
        uint total;
        if(monx >= 3) { 
            monx = 3;
            total = num.mul(tokenRate[token]*MONTH_LP_RATE[monx]).mul(nowtime-starttime).div(xtokens[token].num) / 100;
        } else { 
            uint monEnd = sys_start_time + (monx + 1) * month_sec; 
            while (nowtime > monEnd) {
                profit = profit.add(monEnd.sub(starttime).mul(MONTH_LP_RATE[monx]));
                starttime = monEnd;
                monEnd += month_sec;
                if(monx < 3) monx += 1;
            }
            if(monEnd > nowtime) monEnd =nowtime;
            profit = profit.add(monEnd.sub(starttime).mul(MONTH_LP_RATE[monx]));
            total = num.mul(tokenRate[token]).mul(profit).div(xtokens[token].num) / 100;
        }
        profit = total.mul(89) / 100; 
        opex = total - profit; 
        return (profit, opex);
    }
    function calc_profit(uint num, uint64 starttime, address token) internal view returns(uint profit,uint opex) {
        uint nowtime = block.timestamp;
        if (sys_start_time == 0) return (0, 0);
        if (sys_start_time > nowtime)  return (0, 0); 
        if(starttime < sys_start_time){ 
            starttime = sys_start_time;
        }
        if(xtokens[token].num > 0) {
            if (token == NBK_USDT_PAIR_ADDR || token == NBK_HBTC_PAIR_ADDR || token == NBS_USDT_PAIR_ADDR || token == NBS_HBTC_PAIR_ADDR){ 
                if(starttime > sys_start_time + year_sec) return (0, 0); 
                if(nowtime > sys_start_time + year_sec){ 
                    nowtime = sys_start_time + year_sec;
                }
                (profit, opex) = calc_lp_profit(num, starttime, nowtime, token);
            } else {
                if(starttime > sys_start_time + day5_sec) return (0, 0); 
                if(nowtime > sys_start_time + day5_sec){ 
                    nowtime = sys_start_time + day5_sec;
                }
                profit = num.mul(tokenRate[token]).mul(nowtime-starttime).div(xtokens[token].num);
                opex = 0; 
            }
        }
        return (profit, opex);
    }
    function get_player_count() external view 
    returns(uint64){
        return uint64(players.length - 1);
    }
    function get_player_token_info(uint64 playId, address token) external view 
    returns(
        uint256 num,
        uint256 profit,
        uint64 starttime,
        uint64 sec,
        uint64 pre,
        uint64 next,
        address addr
    ){
        if(playId < 1 || playId >= players.length){
            return(0, 0, 0, 0, 0, 0, address(0));
        }
        TokenInfo storage info;
        addr = idToAddr[playId];
        int8 i = get_token_index(token);
        if (i != NBS_IDX ){
            info = pledge_token[playId][token];
        }else{
            info = vip_token[playId][token];
        }
        uint opex;
        (profit, opex) = calc_profit(info.num, info.starttime, token);
        opex = info.starttime;
        if(info.starttime < sys_start_time){ 
            opex = sys_start_time;
        }
        if(opex > block.timestamp){ 
            opex = block.timestamp;
        }
        return(info.num, info.profit+profit, uint64(opex), uint64(block.timestamp-opex), info.pre, info.next, addr);
    }
    function get_player_profit(uint64 playId) external view 
    returns(
        uint nbkprofit,
        uint nbkvipprofit,
        uint nbsprofit,
        address addr
    ){
        if(playId < 1 || playId >= players.length){
            return(0, 0, 0, address(0));
        }
        addr = idToAddr[playId];
        uint profit;
        uint nbsIdx = uint(NBS_IDX);
        address token;
        uint opex;
        TokenInfo storage tInfo;
        for(uint idx = 0; idx < Init_Token_Addr.length; idx++){
            token = Init_Token_Addr[idx];
            tInfo = pledge_token[playId][token];
            if (idx != nbsIdx) { 
                (profit, opex) = calc_profit(tInfo.num, tInfo.starttime, token);
                profit = tInfo.profit.add(profit); 
                if(profit > 0){
                     if(tInfo.tokentype == 1) {
                        nbkprofit = nbkprofit.add(profit);
                    }else if(tInfo.tokentype == 2) {
                        nbsprofit = nbsprofit.add(profit);
                    }
                }
            }else{
                nbkvipprofit = vip_token[playId][token].profit; 
            }
        }
        return(nbkprofit, nbkvipprofit, nbsprofit, addr);
    }
    function get_xtoken_info(address token) external view 
    returns(
        uint num, 
        uint supply, 
        uint fee, 
        uint opex_fund, 
        uint opex_team, 
        uint opex_investor, 
        uint8 tokentype, 
        uint64 starttime 
    ){
        uint opex;
        uint profit;
        TotalInfo storage aInfo = xtokens[token];
        (profit, opex) = calc_profit(aInfo.num, aInfo.starttime, token);
        supply = aInfo.supply + profit; 
        (opex_fund, opex_team, opex_investor)=calc_opex(opex);
        opex_team += aInfo.opex_team; 
        opex_investor += aInfo.opex_investor; 
        opex_fund += aInfo.opex_fund; 
        opex = aInfo.starttime;
        if(aInfo.starttime < sys_start_time){ 
            opex = sys_start_time;
        }
        return(aInfo.num, supply, aInfo.fee, opex_fund, opex_team, opex_investor, aInfo.tokentype, uint64(opex));
    }
    function get_total_token_info() external view 
    returns(
        uint nbksupply, 
        uint nbkvipsupply, 
        uint nbssupply, 
        uint opexfund, 
        uint opexteam, 
        uint opexinvestor, 
        uint vipusdtnum 
    ){
        uint opex;
        uint profit;
        uint opex_investor;
        uint opex_team;
        TotalInfo storage aInfo;
        address token;
        for(uint idx = 0; idx < Init_Token_Addr.length; idx++){
            token = Init_Token_Addr[idx];
            aInfo = xtokens[token];
            if (idx != uint(NBS_IDX)) { 
                (profit, opex) = calc_profit(aInfo.num, aInfo.starttime, token);
                if(aInfo.tokentype == 1){
                    nbksupply += aInfo.supply; 
                    nbksupply += profit; 
                }else if (aInfo.tokentype == 2){
                    nbssupply += aInfo.supply;
                    nbssupply += profit; 
                    (opex, opex_team, opex_investor)=calc_opex(opex);
                    opexteam += aInfo.opex_team + opex_team; 
                    opexinvestor += aInfo.opex_investor + opex_investor; 
                    opexfund += aInfo.opex_fund + opex; 
                }
            } else {
                nbkvipsupply = aInfo.supply; 
            }
        }
        return(nbksupply, nbkvipsupply, nbssupply, opexfund, opexteam, opexinvestor, vip_usdt_num);
    }
    function calc_opex(uint opex) internal pure returns(uint fund, uint team, uint investor) {
        investor = opex * 2 / 11;
        team = opex * 6 / 11;
        fund = opex - team -investor;
        return(fund, team, investor);
    }
    function balance_of(address token) external view
    returns(
        uint256 tbalance
    ){
        int8 i = get_token_index(token);
        if (i < 0) return 0;
        return IERC20(token).balanceOf(address(this));
    }
}
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
         if (x == 0) {
            return 0;
        }
        uint256 c = x * y;
        require(c / x == y, "ds-math-mul-overflow");
        return c;
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0,'ds-math-div-overflow');
        c = a / b;
    }
}