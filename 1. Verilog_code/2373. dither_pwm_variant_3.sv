//SystemVerilog
module dither_pwm #(parameter N=8)(
    input clk,
    input rst,
    input [N-1:0] din,
    input data_valid,
    output reg pwm,
    output reg pwm_valid
);
    // Error accumulation register
    reg [N-1:0] err_feedback;
    
    // Combined stage: direct computation from inputs
    reg [N:0] sum_direct;
    reg valid_direct;
    
    // Final output stage registers
    reg [N-1:0] next_err;
    
    // Direct computation from inputs to reduce input-to-first-register delay
    always @(posedge clk) begin
        if (rst) begin
            sum_direct <= {(N+1){1'b0}};
            valid_direct <= 1'b0;
        end
        else begin
            sum_direct <= din + err_feedback; // Direct computation from inputs
            valid_direct <= data_valid;
        end
    end
    
    // Output and error feedback stage
    always @(posedge clk) begin
        if (rst) begin
            pwm <= 1'b0;
            next_err <= {N{1'b0}};
            pwm_valid <= 1'b0;
            err_feedback <= {N{1'b0}};
        end
        else begin
            pwm <= sum_direct[N];
            next_err <= sum_direct[N-1:0];
            pwm_valid <= valid_direct;
            err_feedback <= next_err;
        end
    end
endmodule