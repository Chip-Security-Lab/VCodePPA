//SystemVerilog
module async_pipe_mult (
    input [7:0] in1, in2,
    output [15:0] out,
    input req,
    output reg ack
);
    // Internal signals
    reg [7:0] in1_reg, in2_reg;
    reg [15:0] out_reg;
    reg [2:0] state;
    
    // State definitions
    parameter IDLE = 3'b000;
    parameter INPUT_LATCH = 3'b001;
    parameter PARTIAL_MULT = 3'b010;
    parameter FINAL_MULT = 3'b011;
    parameter COMPLETED = 3'b100;
    
    // Handshaking protocol control
    always @(posedge req or posedge ack) begin
        if (ack) begin
            state <= IDLE;
            ack <= 1'b0;
        end else if (req) begin
            case (state)
                IDLE: begin
                    in1_reg <= in1;
                    in2_reg <= in2;
                    state <= INPUT_LATCH;
                end
                
                INPUT_LATCH: begin
                    // First stage of multiplication
                    out_reg[7:0] <= in1_reg[3:0] * in2_reg[3:0];
                    state <= PARTIAL_MULT;
                end
                
                PARTIAL_MULT: begin
                    // Second stage of multiplication
                    out_reg[15:8] <= (in1_reg[7:4] * in2_reg[3:0]) + 
                                   (in1_reg[3:0] * in2_reg[7:4]);
                    state <= FINAL_MULT;
                end
                
                FINAL_MULT: begin
                    // Final stage of multiplication
                    out_reg[15:8] <= out_reg[15:8] + (in1_reg[7:4] * in2_reg[7:4]);
                    state <= COMPLETED;
                end
                
                COMPLETED: begin
                    ack <= 1'b1;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    assign out = out_reg;
    
    initial begin
        state = IDLE;
        ack = 1'b0;
        out_reg = 16'h0000;
    end
endmodule