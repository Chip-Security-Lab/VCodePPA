//SystemVerilog
module PacketParser #(
    parameter CRC_POLY = 32'h04C11DB7
)(
    input clk, rst_n,
    input data_valid,
    input [7:0] data_in,
    output reg [31:0] crc_result,
    output reg packet_valid
);
    // 使用localparam代替typedef enum
    localparam IDLE = 2'b00, HEADER = 2'b01, PAYLOAD = 2'b10, CRC_CHECK = 2'b11;
    reg [1:0] current_state, next_state;
    
    reg [31:0] crc_reg;
    reg [3:0] byte_counter;

    // 流水线寄存器
    reg [31:0] hc_add_stage1_p, hc_add_stage1_g;
    reg [31:0] hc_add_stage2_pp, hc_add_stage2_gp;
    reg [31:0] hc_add_stage3_pp, hc_add_stage3_gp;
    reg [31:0] crc_calc_stage1_data;
    reg [31:0] crc_calc_stage1_crc;
    reg [31:0] crc_calc_stage2_result;
    reg crc_calc_stage1_valid, crc_calc_stage2_valid;

    // 修改CRC计算函数为Verilog兼容的语法并分割关键路径
    function [31:0] calc_crc_stage1;
        input [7:0] data;
        input [31:0] crc;
        reg [31:0] result;
        integer i;
        begin
            result = crc;
            for (i=0; i<4; i=i+1) begin
                if ((data[7-i] ^ result[31]) == 1'b1)
                    result = (result << 1) ^ CRC_POLY;
                else
                    result = result << 1;
            end
            calc_crc_stage1 = result;
        end
    endfunction

    function [31:0] calc_crc_stage2;
        input [7:0] data;
        input [31:0] crc;
        reg [31:0] result;
        integer i;
        begin
            result = crc;
            for (i=4; i<8; i=i+1) begin
                if ((data[7-i] ^ result[31]) == 1'b1)
                    result = (result << 1) ^ CRC_POLY;
                else
                    result = result << 1;
            end
            calc_crc_stage2 = result;
        end
    endfunction
    
    // Han-Carlson加法器阶段1：初始化生成和传播信号
    function [31:0] han_carlson_stage1_p;
        input [31:0] a, b;
        reg [31:0] p;
        integer i;
        begin
            for (i = 0; i < 32; i = i + 1) begin
                p[i] = a[i] ^ b[i];
            end
            han_carlson_stage1_p = p;
        end
    endfunction

    function [31:0] han_carlson_stage1_g;
        input [31:0] a, b;
        reg [31:0] g;
        integer i;
        begin
            for (i = 0; i < 32; i = i + 1) begin
                g[i] = a[i] & b[i];
            end
            han_carlson_stage1_g = g;
        end
    endfunction

    // Han-Carlson加法器阶段2：前缀树操作
    function [31:0] han_carlson_stage2_pp;
        input [31:0] p;
        reg [31:0] pp;
        integer i;
        begin
            pp = p;
            // 预处理阶段
            for (i = 1; i < 32; i = i + 2) begin
                pp[i] = p[i] & p[i-1];
            end
            han_carlson_stage2_pp = pp;
        end
    endfunction

    function [31:0] han_carlson_stage2_gp;
        input [31:0] p, g;
        reg [31:0] gp;
        integer i;
        begin
            gp = g;
            // 预处理阶段
            for (i = 1; i < 32; i = i + 2) begin
                gp[i] = g[i] | (p[i] & g[i-1]);
            end
            han_carlson_stage2_gp = gp;
        end
    endfunction

    // Han-Carlson加法器阶段3：树形和后处理阶段
    function [31:0] han_carlson_stage3;
        input [31:0] pp, gp, p;
        reg [31:0] sum;
        reg [31:0] pp_temp, gp_temp;
        integer i, j;
        begin
            pp_temp = pp;
            gp_temp = gp;
            
            // 树形阶段
            for (i = 2; i < 32; i = i * 2) begin
                for (j = i + 1; j < 32; j = j + 2) begin
                    if (j >= i) begin
                        pp_temp[j] = pp_temp[j] & pp_temp[j-i];
                        gp_temp[j] = gp_temp[j] | (pp_temp[j] & gp_temp[j-i]);
                    end
                end
            end
            
            // 后处理阶段
            for (i = 2; i < 32; i = i + 2) begin
                pp_temp[i] = pp_temp[i] & pp_temp[i-1];
                gp_temp[i] = gp_temp[i] | (pp_temp[i] & gp_temp[i-1]);
            end
            
            // 计算最终和
            sum[0] = p[0];
            for (i = 1; i < 32; i = i + 1) begin
                sum[i] = p[i] ^ gp_temp[i-1];
            end
            
            han_carlson_stage3 = sum;
        end
    endfunction

    // 流水线阶段1: CRC计算第一阶段和Han-Carlson加法器初始化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_calc_stage1_data <= 0;
            crc_calc_stage1_crc <= 0;
            crc_calc_stage1_valid <= 0;
            hc_add_stage1_p <= 0;
            hc_add_stage1_g <= 0;
        end else begin
            if (current_state == PAYLOAD && data_valid) begin
                crc_calc_stage1_data <= data_in;
                crc_calc_stage1_crc <= crc_reg;
                crc_calc_stage1_valid <= 1;
            end else begin
                crc_calc_stage1_valid <= 0;
            end
            
            // Han-Carlson加法器阶段1寄存器更新 - 只在需要时计算
            if (current_state == PAYLOAD && data_valid) begin
                // 这里假设最需要被流水线化的是来自CRC计算的关键路径
                hc_add_stage1_p <= han_carlson_stage1_p(crc_reg << 1, CRC_POLY);
                hc_add_stage1_g <= han_carlson_stage1_g(crc_reg << 1, CRC_POLY);
            end
        end
    end

    // 流水线阶段2: CRC计算第二阶段和Han-Carlson加法器中间阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_calc_stage2_result <= 0;
            crc_calc_stage2_valid <= 0;
            hc_add_stage2_pp <= 0;
            hc_add_stage2_gp <= 0;
        end else begin
            if (crc_calc_stage1_valid) begin
                crc_calc_stage2_result <= calc_crc_stage1(crc_calc_stage1_data, crc_calc_stage1_crc);
                crc_calc_stage2_valid <= 1;
            end else begin
                crc_calc_stage2_valid <= 0;
            end
            
            // Han-Carlson加法器阶段2寄存器更新
            if (crc_calc_stage1_valid) begin
                hc_add_stage2_pp <= han_carlson_stage2_pp(hc_add_stage1_p);
                hc_add_stage2_gp <= han_carlson_stage2_gp(hc_add_stage1_p, hc_add_stage1_g);
            end
        end
    end

    // 流水线阶段3: Han-Carlson加法器最终阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hc_add_stage3_pp <= 0;
            hc_add_stage3_gp <= 0;
        end else begin
            if (crc_calc_stage2_valid) begin
                hc_add_stage3_pp <= hc_add_stage2_pp;
                hc_add_stage3_gp <= hc_add_stage2_gp;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            crc_reg <= 32'hFFFFFFFF;
            byte_counter <= 0;
            crc_result <= 0;
            packet_valid <= 0;
        end else begin
            current_state <= next_state;
            packet_valid <= 0; // 默认复位packet_valid
            
            case(current_state)
                IDLE: begin
                    if (data_valid && data_in == 8'h55) begin
                        crc_reg <= 32'hFFFFFFFF; // 重置CRC寄存器
                    end
                end
                
                HEADER: begin
                    if (data_valid) begin
                        if (byte_counter == 3) begin
                            byte_counter <= 0;
                        end else begin
                            byte_counter <= byte_counter + 1;
                        end
                    end
                end
                
                PAYLOAD: begin
                    // 延迟2个周期更新CRC以匹配流水线
                    if (crc_calc_stage2_valid) begin
                        crc_reg <= calc_crc_stage2(crc_calc_stage1_data, crc_calc_stage2_result);
                    end
                end
                
                CRC_CHECK: begin
                    crc_result <= crc_reg;
                    packet_valid <= (crc_reg == 32'h0);
                end
                
                default: ;
            endcase
        end
    end

    always @(*) begin
        next_state = current_state;
        case(current_state)
            IDLE: if (data_in == 8'h55 && data_valid) next_state = HEADER;
            HEADER: if (byte_counter == 3 && data_valid) next_state = PAYLOAD;
            PAYLOAD: if (data_in == 8'hAA && data_valid) next_state = CRC_CHECK;
            CRC_CHECK: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
endmodule