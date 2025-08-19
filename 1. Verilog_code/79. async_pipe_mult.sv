module async_pipe_mult (
    input [7:0] in1, in2,
    output [15:0] out,
    input req,
    output reg ack
);
    // Internal signals
    reg [7:0] in1_reg, in2_reg;
    reg [15:0] out_reg;
    reg [1:0] state;
    
    // State definitions
    parameter IDLE = 2'b00;
    parameter COMPUTING = 2'b01;
    parameter COMPLETED = 2'b10;
    
    // Handshaking protocol control
    always @(posedge req or posedge ack) begin
        if (ack) begin
            // Reset when acknowledgment is sent
            state <= IDLE;
            ack <= 1'b0;
        end else if (req) begin
            case (state)
                IDLE: begin
                    // Latch inputs
                    in1_reg <= in1;
                    in2_reg <= in2;
                    state <= COMPUTING;
                end
                
                COMPUTING: begin
                    // Compute product
                    out_reg <= in1_reg * in2_reg;
                    state <= COMPLETED;
                end
                
                COMPLETED: begin
                    // Assert acknowledgment
                    ack <= 1'b1;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // Output assignment
    assign out = out_reg;
    
    // Initial state
    initial begin
        state = IDLE;
        ack = 1'b0;
        out_reg = 16'h0000;
    end
endmodule