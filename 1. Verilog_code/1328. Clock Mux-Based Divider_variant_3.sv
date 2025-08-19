//SystemVerilog
module mux_divider (
    input wire main_clock, 
    input wire reset, 
    input wire enable,
    input wire [1:0] select,
    output reg out_clock
);
    // Counter registers
    reg [3:0] divider;
    
    // Internally registered output signals for each select case
    reg out_clock_0, out_clock_1, out_clock_2, out_clock_3;
    
    // Clock divider counter logic
    always @(posedge main_clock or posedge reset) begin
        if (reset) begin
            divider <= 4'b0000;
            out_clock_0 <= 1'b0;
            out_clock_1 <= 1'b0;
            out_clock_2 <= 1'b0;
            out_clock_3 <= 1'b0;
        end 
        else if (enable) begin
            divider <= divider + 1'b1;
            out_clock_0 <= divider[0];
            out_clock_1 <= divider[1];
            out_clock_2 <= divider[2];
            out_clock_3 <= divider[3];
        end
    end
    
    // Registered output selection to reduce critical path
    always @(posedge main_clock or posedge reset) begin
        if (reset) begin
            out_clock <= 1'b0;
        end
        else begin
            case (select)
                2'b00: out_clock <= out_clock_0;
                2'b01: out_clock <= out_clock_1;
                2'b10: out_clock <= out_clock_2;
                2'b11: out_clock <= out_clock_3;
            endcase
        end
    end
    
endmodule