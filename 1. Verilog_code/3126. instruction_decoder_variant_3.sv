//SystemVerilog
module instruction_decoder(
    input wire clk,
    input wire reset,
    input wire [15:0] instruction,
    input wire ready,
    output reg [3:0] alu_op,
    output reg [3:0] src_reg,
    output reg [3:0] dst_reg,
    output reg [7:0] immediate,
    output reg mem_read,
    output reg mem_write,
    output reg reg_write,
    output reg immediate_valid
);
    parameter [1:0] IDLE = 2'b00, DECODE = 2'b01, 
                    EXECUTE = 2'b10, WRITEBACK = 2'b11;
    reg [1:0] state, next_state;
    
    // Baugh-Wooley multiplier signals
    wire [15:0] mul_result;
    reg [15:0] mul_a, mul_b;
    wire [15:0] partial_products [0:15];
    wire [15:0] sum_products;
    
    // Generate partial products
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_partial_products
            assign partial_products[i] = mul_a & {16{mul_b[i]}};
        end
    endgenerate
    
    // Sum partial products with sign extension
    assign sum_products = partial_products[0] + 
                         (partial_products[1] << 1) +
                         (partial_products[2] << 2) +
                         (partial_products[3] << 3) +
                         (partial_products[4] << 4) +
                         (partial_products[5] << 5) +
                         (partial_products[6] << 6) +
                         (partial_products[7] << 7) +
                         (partial_products[8] << 8) +
                         (partial_products[9] << 9) +
                         (partial_products[10] << 10) +
                         (partial_products[11] << 11) +
                         (partial_products[12] << 12) +
                         (partial_products[13] << 13) +
                         (partial_products[14] << 14) +
                         (partial_products[15] << 15);
    
    // Final result with sign correction
    assign mul_result = sum_products ^ {16{1'b1}} + 1'b1;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            alu_op <= 4'd0;
            src_reg <= 4'd0;
            dst_reg <= 4'd0;
            immediate <= 8'd0;
            mem_read <= 1'b0;
            mem_write <= 1'b0;
            reg_write <= 1'b0;
            immediate_valid <= 1'b0;
            mul_a <= 16'd0;
            mul_b <= 16'd0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    mem_read <= 1'b0;
                    mem_write <= 1'b0;
                    reg_write <= 1'b0;
                    immediate_valid <= 1'b0;
                end
                DECODE: begin
                    alu_op <= instruction[15:12];
                    dst_reg <= instruction[11:8];
                    src_reg <= instruction[7:4];
                    immediate <= {4'b0000, instruction[3:0]};
                    
                    case (instruction[15:12])
                        4'b0000: begin // NOP
                            mem_read <= 1'b0;
                            mem_write <= 1'b0;
                            reg_write <= 1'b0;
                            immediate_valid <= 1'b0;
                        end
                        4'b0001: begin // ADD
                            mem_read <= 1'b0;
                            mem_write <= 1'b0;
                            reg_write <= 1'b1;
                            immediate_valid <= 1'b0;
                        end
                        4'b0010: begin // SUB
                            mem_read <= 1'b0;
                            mem_write <= 1'b0;
                            reg_write <= 1'b1;
                            immediate_valid <= 1'b0;
                        end
                        4'b0011: begin // ADDI
                            mem_read <= 1'b0;
                            mem_write <= 1'b0;
                            reg_write <= 1'b1;
                            immediate_valid <= 1'b1;
                        end
                        4'b0100: begin // LOAD
                            mem_read <= 1'b1;
                            mem_write <= 1'b0;
                            reg_write <= 1'b1;
                            immediate_valid <= 1'b0;
                        end
                        4'b0101: begin // STORE
                            mem_read <= 1'b0;
                            mem_write <= 1'b1;
                            reg_write <= 1'b0;
                            immediate_valid <= 1'b0;
                        end
                        4'b0110: begin // MUL
                            mem_read <= 1'b0;
                            mem_write <= 1'b0;
                            reg_write <= 1'b1;
                            immediate_valid <= 1'b0;
                            mul_a <= {8'd0, instruction[7:0]};
                            mul_b <= {8'd0, instruction[15:8]};
                        end
                        default: begin
                            mem_read <= 1'b0;
                            mem_write <= 1'b0;
                            reg_write <= 1'b0;
                            immediate_valid <= 1'b0;
                        end
                    endcase
                end
                EXECUTE: begin
                    // Maintain control signals during execution
                end
                WRITEBACK: begin
                    mem_read <= 1'b0;
                    mem_write <= 1'b0;
                    reg_write <= 1'b0;
                end
            endcase
        end
    end
    
    always @(*) begin
        case (state)
            IDLE: begin
                next_state = ready ? DECODE : IDLE;
            end
            DECODE: begin
                next_state = EXECUTE;
            end
            EXECUTE: begin
                next_state = WRITEBACK;
            end
            WRITEBACK: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule