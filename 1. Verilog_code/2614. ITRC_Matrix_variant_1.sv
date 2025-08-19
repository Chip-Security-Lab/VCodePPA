//SystemVerilog
module ITRC_Matrix #(
    parameter SOURCES = 4,
    parameter TARGETS = 2
)(
    input clk,
    input rst_n,
    input [SOURCES-1:0] int_src,
    input [TARGETS*SOURCES-1:0] routing_map,
    output reg [TARGETS-1:0] int_out
);

    // Internal signals for shift-add multiplier
    reg [SOURCES-1:0] src_reg;
    reg [SOURCES-1:0] mask_reg;
    reg [SOURCES:0] acc_reg;
    reg [2:0] state;
    reg [2:0] bit_cnt;
    reg [1:0] target_cnt;
    
    // State definitions
    localparam IDLE = 3'b000;
    localparam LOAD = 3'b001;
    localparam MULT = 3'b010;
    localparam DONE = 3'b011;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_cnt <= 0;
            target_cnt <= 0;
            acc_reg <= 0;
            int_out <= 0;
        end else begin
            case (state)
                IDLE: begin
                    state <= LOAD;
                    bit_cnt <= 0;
                    target_cnt <= 0;
                end
                
                LOAD: begin
                    src_reg <= int_src;
                    mask_reg <= routing_map[target_cnt*SOURCES +: SOURCES];
                    acc_reg <= 0;
                    state <= MULT;
                end
                
                MULT: begin
                    if (bit_cnt < SOURCES) begin
                        if (mask_reg[bit_cnt])
                            acc_reg <= acc_reg + (src_reg << bit_cnt);
                        bit_cnt <= bit_cnt + 1;
                    end else begin
                        int_out[target_cnt] <= |acc_reg;
                        if (target_cnt < TARGETS-1) begin
                            target_cnt <= target_cnt + 1;
                            state <= LOAD;
                        end else begin
                            state <= DONE;
                        end
                    end
                end
                
                DONE: begin
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule