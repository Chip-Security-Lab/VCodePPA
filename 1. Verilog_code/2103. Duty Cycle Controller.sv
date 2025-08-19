module duty_cycle_controller(
    input wire clock_in,
    input wire reset,
    input wire [3:0] duty_cycle, // 0-15 (0%-93.75%)
    output reg clock_out
);
    reg [3:0] count;
    
    always @(posedge clock_in) begin
        if (reset) begin
            count <= 4'd0;
            clock_out <= 1'b0;
        end else begin
            if (count < 4'd15)
                count <= count + 1'b1;
            else
                count <= 4'd0;
                
            clock_out <= (count < duty_cycle) ? 1'b1 : 1'b0;
        end
    end
endmodule