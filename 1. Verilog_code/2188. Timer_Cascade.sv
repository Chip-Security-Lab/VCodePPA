module Timer_Cascade #(parameter STAGES=2) (
    input clk, rst, en,
    output cascade_done
);
    genvar i;
    wire [STAGES:0] carry;
    assign carry[0] = en;
    assign cascade_done = carry[STAGES];
    
    generate for(i=0; i<STAGES; i=i+1) begin: stage
        reg [3:0] cnt;
        always @(posedge clk or posedge rst) begin
            if (rst) cnt <= 0;
            else if (carry[i]) 
                cnt <= (cnt == 15) ? 0 : cnt + 1;
        end
        assign carry[i+1] = (cnt == 15) ? carry[i] : 0;
    end endgenerate
endmodule