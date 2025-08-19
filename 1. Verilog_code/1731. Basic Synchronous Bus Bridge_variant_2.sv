//SystemVerilog
module sync_bus_bridge #(parameter DWIDTH=32, AWIDTH=8) (
    input clk, rst_n,
    input [AWIDTH-1:0] src_addr, dst_addr,
    input [DWIDTH-1:0] src_data,
    input src_valid, dst_ready,
    output reg [DWIDTH-1:0] dst_data,
    output reg src_ready, dst_valid
);

    // 预计算控制信号
    wire transfer_condition = src_valid && src_ready;
    wire release_condition = dst_valid && dst_ready;
    
    // 状态寄存器
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam TRANSFER = 2'b01;
    localparam WAIT = 2'b10;

    // 流水线寄存器
    reg [DWIDTH-1:0] src_data_reg;
    reg transfer_valid_reg, release_valid_reg;

    // 流水线控制信号
    reg valid_stage1, valid_stage2;

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            dst_data <= 0;
            dst_valid <= 0;
            src_ready <= 1;
            src_data_reg <= 0;
            valid_stage1 <= 0;
            valid_stage2 <= 0;
        end else begin
            // 流水线阶段1
            if (transfer_condition) begin
                src_data_reg <= src_data;
                valid_stage1 <= 1;
                src_ready <= 0;
            end else begin
                valid_stage1 <= 0;
            end

            // 流水线阶段2
            if (valid_stage1) begin
                dst_data <= src_data_reg;
                dst_valid <= 1;
                valid_stage2 <= 1;
            end else begin
                valid_stage2 <= 0;
            end

            // 状态机
            case (state)
                IDLE: begin
                    if (valid_stage2) begin
                        state <= TRANSFER;
                    end
                end
                TRANSFER: begin
                    if (release_condition) begin
                        state <= IDLE;
                        dst_valid <= 0;
                        src_ready <= 1;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule