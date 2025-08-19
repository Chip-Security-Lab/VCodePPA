module timeout_ismu(
    input clk, rst_n,
    input [3:0] irq_in,
    input [3:0] irq_mask,
    input [7:0] timeout_val,
    output reg [3:0] irq_out,
    output reg timeout_flag
);
    reg [7:0] counter [3:0];
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_out <= 4'h0;
            timeout_flag <= 1'b0;
            for (i = 0; i < 4; i = i + 1)
                counter[i] <= 8'h0;
        end else begin
            timeout_flag <= 1'b0;
            for (i = 0; i < 4; i = i + 1) begin
                if (irq_in[i] && !irq_mask[i]) begin
                    if (counter[i] < timeout_val)
                        counter[i] <= counter[i] + 8'h1;
                    else begin
                        timeout_flag <= 1'b1;
                        irq_out[i] <= 1'b1;
                    end
                end else begin
                    counter[i] <= 8'h0;
                    irq_out[i] <= 1'b0;
                end
            end
        end
    end
endmodule