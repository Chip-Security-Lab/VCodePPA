//SystemVerilog
module dram_ctrl_pipelined #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32
)(
    input clk,
    input rst_n,
    input cmd_valid,
    input [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg ready
);

    localparam IDLE = 3'd0,
               ACTIVE = 3'd1,
               READ = 3'd2,
               WRITE = 3'd3,
               PRECHARGE = 3'd4;

    reg [2:0] state_stage1, state_stage2, state_stage3, state_stage4;
    reg [ADDR_WIDTH-1:0] addr_stage1, addr_stage2;
    reg [3:0] timer_stage2, timer_stage4;
    reg [DATA_WIDTH-1:0] data_stage3;
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;

    // Stage 1: Command Decode & Address Latch
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            addr_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            case ({cmd_valid, ready})
                2'b11: begin
                    state_stage1 <= ACTIVE;
                    addr_stage1 <= addr;
                    valid_stage1 <= 1;
                end
                default: begin
                    state_stage1 <= IDLE;
                    valid_stage1 <= 0;
                end
            endcase
        end
    end

    // Stage 2: Activation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            addr_stage2 <= 0;
            timer_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            case (valid_stage1)
                1'b1: begin
                    state_stage2 <= state_stage1;
                    addr_stage2 <= addr_stage1;
                    timer_stage2 <= 4'd3;
                    valid_stage2 <= 1;
                end
                default: begin
                    case (timer_stage2 > 0)
                        1'b1: timer_stage2 <= timer_stage2 - 1;
                        default: valid_stage2 <= 0;
                    endcase
                end
            endcase
        end
    end

    // Stage 3: Read/Write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage3 <= IDLE;
            data_stage3 <= 0;
            valid_stage3 <= 0;
        end else begin
            case ({valid_stage2, timer_stage2 == 0})
                2'b11: begin
                    state_stage3 <= READ;
                    data_stage3 <= {DATA_WIDTH{1'b1}};
                    valid_stage3 <= 1;
                end
                default: valid_stage3 <= 0;
            endcase
        end
    end

    // Stage 4: Precharge
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage4 <= IDLE;
            timer_stage4 <= 0;
            valid_stage4 <= 0;
        end else begin
            case (valid_stage3)
                1'b1: begin
                    state_stage4 <= PRECHARGE;
                    timer_stage4 <= 4'd2;
                    valid_stage4 <= 1;
                end
                default: begin
                    case (timer_stage4 > 0)
                        1'b1: timer_stage4 <= timer_stage4 - 1;
                        default: valid_stage4 <= 0;
                    endcase
                end
            endcase
        end
    end

    // Output Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 0;
            ready <= 1;
        end else begin
            case (valid_stage3)
                1'b1: data_out <= data_stage3;
                default: data_out <= data_out;
            endcase
            ready <= (state_stage4 == IDLE) && (timer_stage4 == 0);
        end
    end

endmodule