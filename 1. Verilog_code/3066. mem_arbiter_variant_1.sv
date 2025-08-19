//SystemVerilog
module mem_arbiter(
    input wire clk, rst,
    input wire req1, req2, req3,
    input wire [7:0] addr1, addr2, addr3,
    input wire [7:0] wdata1, wdata2, wdata3,
    input wire wen1, wen2, wen3,
    output reg [7:0] addr_out, wdata_out,
    output reg wen_out, grant1, grant2, grant3
);

    localparam IDLE=3'd0, GRANT1=3'd1, GRANT2=3'd2, GRANT3=3'd3;
    reg [2:0] state, next;
    
    // 缓冲寄存器
    reg [7:0] addr_buf, wdata_buf;
    reg wen_buf;
    reg [7:0] d0_buf, d1_buf;
    
    // 移位累加乘法器相关信号
    reg [7:0] mult_a, mult_b;
    reg [15:0] mult_result;
    reg [3:0] mult_cnt;
    reg mult_busy;

    // 状态寄存器更新
    always @(posedge clk) begin
        if (rst) state <= IDLE;
        else state <= next;
    end

    // 乘法器控制逻辑
    always @(posedge clk) begin
        if (rst) begin
            mult_busy <= 1'b0;
            mult_cnt <= 4'd0;
        end else if (!mult_busy) begin
            mult_busy <= 1'b1;
            mult_cnt <= 4'd0;
        end else if (mult_cnt < 4'd8) begin
            mult_cnt <= mult_cnt + 1'b1;
        end else begin
            mult_busy <= 1'b0;
        end
    end

    // 乘法器计算逻辑
    always @(posedge clk) begin
        if (rst) begin
            mult_result <= 16'd0;
        end else if (mult_busy && mult_cnt < 4'd8) begin
            if (mult_b[mult_cnt]) begin
                mult_result <= mult_result + (mult_a << mult_cnt);
            end
        end else if (!mult_busy) begin
            mult_result <= 16'd0;
        end
    end

    // 缓冲寄存器更新
    always @(posedge clk) begin
        if (rst) begin
            addr_buf <= 8'd0;
            wdata_buf <= 8'd0;
            wen_buf <= 1'b0;
            d0_buf <= 8'd0;
            d1_buf <= 8'd0;
        end else begin
            addr_buf <= addr_out;
            wdata_buf <= wdata_out;
            wen_buf <= wen_out;
            d0_buf <= mult_a;
            d1_buf <= mult_b;
        end
    end

    // 仲裁器输出逻辑
    always @(*) begin
        grant1 = 1'b0;
        grant2 = 1'b0;
        grant3 = 1'b0;
        addr_out = 8'd0;
        wdata_out = 8'd0;
        wen_out = 1'b0;
        mult_a = 8'd0;
        mult_b = 8'd0;
    end

    // 状态转换逻辑
    always @(*) begin
        next = state;
        case (state)
            IDLE: begin
                if (req1) next = GRANT1;
                else if (req2) next = GRANT2;
                else if (req3) next = GRANT3;
            end
            GRANT1: begin
                if (!req1) begin
                    if (req2) next = GRANT2;
                    else if (req3) next = GRANT3;
                    else next = IDLE;
                end
            end
            GRANT2: begin
                if (!req2) begin
                    if (req3) next = GRANT3;
                    else if (req1) next = GRANT1;
                    else next = IDLE;
                end
            end
            GRANT3: begin
                if (!req3) begin
                    if (req1) next = GRANT1;
                    else if (req2) next = GRANT2;
                    else next = IDLE;
                end
            end
            default: next = IDLE;
        endcase
    end

    // 输出控制逻辑
    always @(*) begin
        case (state)
            GRANT1: begin
                grant1 = 1'b1;
                addr_out = addr1;
                mult_a = wdata1;
                mult_b = 8'd1;
                wdata_out = mult_result[7:0];
                wen_out = wen1;
            end
            GRANT2: begin
                grant2 = 1'b1;
                addr_out = addr2;
                mult_a = wdata2;
                mult_b = 8'd1;
                wdata_out = mult_result[7:0];
                wen_out = wen2;
            end
            GRANT3: begin
                grant3 = 1'b1;
                addr_out = addr3;
                mult_a = wdata3;
                mult_b = 8'd1;
                wdata_out = mult_result[7:0];
                wen_out = wen3;
            end
        endcase
    end
endmodule