//SystemVerilog
module parity_reg(
    input wire clk, reset,
    input wire [7:0] data,
    input wire valid,
    output wire ready,
    output reg [8:0] data_with_parity
);
    // State encoding - one-hot encoding for better timing
    localparam IDLE = 1'b0;
    localparam BUSY = 1'b1;
    
    // State register
    reg state;
    
    // Pre-calculate parity bit
    wire parity_bit;
    assign parity_bit = ^data;
    
    // Ready signal directly from state
    assign ready = (state == IDLE);
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_with_parity <= 9'b0;
            state <= IDLE;
        end
        else begin
            case (state)
                IDLE: begin
                    if (valid) begin
                        // Combine data and parity in single assignment
                        data_with_parity <= {parity_bit, data};
                        state <= BUSY;
                    end
                end
                
                BUSY: begin
                    state <= IDLE; // Return to IDLE after one cycle
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule