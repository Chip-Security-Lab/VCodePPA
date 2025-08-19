//SystemVerilog
module ITRC_SequenceDetect #(
    parameter SEQ_PATTERN = 3'b101
)(
    input clk,
    input rst_n,
    input int_in,
    output reg seq_detected
);

    // Booth multiplier signals
    reg [2:0] booth_a;
    reg [2:0] booth_b;
    reg [5:0] booth_p;
    reg [2:0] booth_result;
    
    reg [2:0] shift_reg;
    
    // Booth multiplier implementation
    always @(posedge clk) begin
        if (!rst_n) begin
            shift_reg <= 0;
            booth_p <= 0;
        end else begin
            shift_reg <= {shift_reg[1:0], int_in};
            
            // Initialize booth operands
            booth_a = shift_reg;
            booth_b = SEQ_PATTERN;
            
            // Booth algorithm
            booth_p = 0;
            for (int i = 0; i < 3; i = i + 1) begin
                case ({booth_a[0], booth_p[0]})
                    2'b00, 2'b11: booth_p = booth_p >> 1;
                    2'b01: booth_p = (booth_p + {booth_b, 3'b0}) >> 1;
                    2'b10: booth_p = (booth_p - {booth_b, 3'b0}) >> 1;
                endcase
                booth_a = booth_a >> 1;
            end
            
            booth_result = booth_p[2:0];
        end
    end
    
    always @* begin
        seq_detected = (booth_result == 0);
    end

endmodule