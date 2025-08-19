module quad_clock_gen(
    input clock_in,
    input reset,
    output reg clock_0,
    output reg clock_90,
    output reg clock_180,
    output reg clock_270
);
    reg [1:0] phase_counter;
    
    always @(posedge clock_in or posedge reset) begin
        if (reset)
            phase_counter <= 2'b00;
        else
            phase_counter <= phase_counter + 1'b1;
            
        clock_0 <= (phase_counter == 2'b00);
        clock_90 <= (phase_counter == 2'b01);
        clock_180 <= (phase_counter == 2'b10);
        clock_270 <= (phase_counter == 2'b11);
    end
endmodule