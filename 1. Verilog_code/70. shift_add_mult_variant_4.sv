//SystemVerilog
module shift_add_mult (
    input clk,
    input rst_n,
    input req,
    output reg ack,
    input [7:0] mplier,
    input [7:0] mcand,
    output reg [15:0] result
);

    reg [15:0] partial_products [7:0];
    reg [15:0] sum_stage1 [3:0];
    reg [15:0] sum_stage2 [1:0];
    reg [15:0] final_sum;
    reg req_reg;
    reg processing;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_reg <= 1'b0;
            processing <= 1'b0;
            ack <= 1'b0;
        end else begin
            req_reg <= req;
            
            if (req && !req_reg && !processing) begin
                processing <= 1'b1;
                ack <= 1'b0;
            end
            
            if (processing) begin
                // Generate partial products
                for (int i=0; i<8; i=i+1) begin
                    partial_products[i] <= mplier[i] ? (mcand << i) : 16'b0;
                end
                
                // First stage of addition
                sum_stage1[0] <= partial_products[0] + partial_products[1];
                sum_stage1[1] <= partial_products[2] + partial_products[3];
                sum_stage1[2] <= partial_products[4] + partial_products[5];
                sum_stage1[3] <= partial_products[6] + partial_products[7];
                
                // Second stage of addition
                sum_stage2[0] <= sum_stage1[0] + sum_stage1[1];
                sum_stage2[1] <= sum_stage1[2] + sum_stage1[3];
                
                // Final addition
                final_sum <= sum_stage2[0] + sum_stage2[1];
                result <= final_sum;
                
                processing <= 1'b0;
                ack <= 1'b1;
            end
            
            if (ack && !req) begin
                ack <= 1'b0;
            end
        end
    end

endmodule