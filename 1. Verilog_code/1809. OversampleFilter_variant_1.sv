//SystemVerilog
module OversampleFilter #(parameter OVERSAMPLE=3) (
    input clk,
    input rst,
    input din,
    input valid_in,
    output reg dout,
    output reg valid_out
);
    // Stage 1: Sample shift register
    reg [OVERSAMPLE-1:0] sample_buf;
    reg valid_stage1;
    
    // Stage 2: Count ones
    reg [3:0] count_stage2;
    reg valid_stage2;
    
    // Stage 3: Majority decision
    
    // Pipeline Stage 1: Update shift register
    always @(posedge clk) begin
        if (rst) begin
            sample_buf <= 0;
            valid_stage1 <= 0;
        end
        else begin
            if (valid_in) begin
                sample_buf <= {sample_buf[OVERSAMPLE-2:0], din};
                valid_stage1 <= 1'b1;
            end
            else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Pipeline Stage 2: Count ones
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            count_stage2 <= 0;
            valid_stage2 <= 0;
        end
        else begin
            valid_stage2 <= valid_stage1;
            
            if (valid_stage1) begin
                count_stage2 <= 0;
                for(i=0; i<OVERSAMPLE; i=i+1)
                    if(sample_buf[i]) count_stage2 <= count_stage2 + 1;
            end
        end
    end
    
    // Pipeline Stage 3: Majority decision
    always @(posedge clk) begin
        if (rst) begin
            dout <= 0;
            valid_out <= 0;
        end
        else begin
            valid_out <= valid_stage2;
            
            if (valid_stage2) begin
                dout <= (count_stage2 > (OVERSAMPLE/2));
            end
        end
    end
endmodule