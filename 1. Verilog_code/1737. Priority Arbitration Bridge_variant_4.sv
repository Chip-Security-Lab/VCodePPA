//SystemVerilog
module priority_bridge #(parameter DWIDTH=32) (
    input clk, rst_n,
    input [DWIDTH-1:0] high_data, low_data,
    input high_valid, low_valid,
    output reg high_ready, low_ready,
    output reg [DWIDTH-1:0] out_data,
    output reg out_valid,
    input out_ready
);

    localparam [2:0] RESET    = 3'b000;
    localparam [2:0] HIGH_PRI = 3'b001;
    localparam [2:0] LOW_PRI  = 3'b011;
    localparam [2:0] OUTPUT   = 3'b010;
    localparam [2:0] IDLE     = 3'b110;
    
    reg [2:0] state, next_state;
    reg [DWIDTH-1:0] data_reg;
    reg valid_reg;
    reg high_ready_reg, low_ready_reg;

    // 状态转换逻辑
    always @(*) begin
        case (state)
            RESET: next_state = (!rst_n) ? RESET : (high_valid ? HIGH_PRI : (low_valid ? LOW_PRI : IDLE));
            HIGH_PRI: next_state = (!rst_n) ? RESET : ((out_valid && out_ready) ? IDLE : HIGH_PRI);
            LOW_PRI: next_state = (!rst_n) ? RESET : ((out_valid && out_ready) ? IDLE : LOW_PRI);
            OUTPUT: next_state = (!rst_n) ? RESET : ((out_valid && out_ready) ? IDLE : OUTPUT);
            IDLE: next_state = (!rst_n) ? RESET : (high_valid ? HIGH_PRI : (low_valid ? LOW_PRI : IDLE));
            default: next_state = RESET;
        endcase
    end

    // 状态寄存器更新
    always @(posedge clk) begin
        if (!rst_n) state <= RESET;
        else state <= next_state;
    end

    // 数据路径逻辑
    always @(posedge clk) begin
        if (!rst_n) begin
            data_reg <= 0;
            valid_reg <= 0;
        end else begin
            case (state)
                HIGH_PRI: begin
                    data_reg <= high_data;
                    valid_reg <= 1;
                end
                LOW_PRI: begin
                    if (low_valid) begin
                        data_reg <= low_data;
                        valid_reg <= 1;
                    end
                end
                OUTPUT: begin
                    if (out_valid && out_ready) begin
                        valid_reg <= 0;
                    end
                end
            endcase
        end
    end

    // 就绪信号逻辑
    always @(posedge clk) begin
        if (!rst_n) begin
            high_ready_reg <= 1;
            low_ready_reg <= 1;
        end else begin
            case (state)
                HIGH_PRI: begin
                    high_ready_reg <= 0;
                    low_ready_reg <= 0;
                end
                LOW_PRI: begin
                    if (low_valid) begin
                        high_ready_reg <= 0;
                        low_ready_reg <= 0;
                    end
                end
                OUTPUT: begin
                    if (out_valid && out_ready) begin
                        high_ready_reg <= 1;
                        low_ready_reg <= 1;
                    end
                end
                IDLE: begin
                    high_ready_reg <= 1;
                    low_ready_reg <= 1;
                end
            endcase
        end
    end

    // 输出寄存器
    always @(posedge clk) begin
        if (!rst_n) begin
            out_data <= 0;
            out_valid <= 0;
            high_ready <= 1;
            low_ready <= 1;
        end else begin
            out_data <= data_reg;
            out_valid <= valid_reg;
            high_ready <= high_ready_reg;
            low_ready <= low_ready_reg;
        end
    end

endmodule