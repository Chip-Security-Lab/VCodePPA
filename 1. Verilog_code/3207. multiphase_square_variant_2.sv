//SystemVerilog
module multiphase_square(
    input wire clock,
    input wire reset_n,
    input wire [7:0] period,
    output reg [3:0] phase_outputs
);
    reg [7:0] count;
    
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            count <= 8'd0;
            phase_outputs <= 4'b0001;
        end else begin
            if (count == period-1) begin
                count <= 8'd0;
                phase_outputs <= {phase_outputs[2:0], phase_outputs[3]};
            end else begin
                count <= count + 1'b1;
            end
        end
    end
endmodule