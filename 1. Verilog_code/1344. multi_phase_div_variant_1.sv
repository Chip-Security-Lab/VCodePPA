//SystemVerilog
module multi_phase_div #(parameter N=4) (
    input clk, rst,
    output reg [3:0] phase_out
);
    reg [1:0] cnt;
    
    always @(posedge clk) begin
        if(rst) begin
            cnt <= 0;
            phase_out <= 4'b0001; // Reset to initial phase
        end
        else begin
            cnt <= cnt + 1;
            
            // Generate phase outputs directly from counter value
            // instead of using intermediate combinational logic
            phase_out[3] <= (cnt == 2); // Forward retimed: detecting cnt==3 one cycle earlier
            phase_out[2] <= (cnt == 1); // Forward retimed: detecting cnt==2 one cycle earlier
            phase_out[1] <= (cnt == 0); // Forward retimed: detecting cnt==1 one cycle earlier
            phase_out[0] <= (cnt == 3); // Forward retimed: detecting cnt==0 one cycle earlier
        end
    end
endmodule