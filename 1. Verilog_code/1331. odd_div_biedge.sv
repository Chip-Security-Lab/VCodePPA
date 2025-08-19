module odd_div_biedge #(parameter N=5) (
    input clk, rst_n,
    output clk_out
);
// To implement a dual-edge counter, create separate logic
// for positive and negative edges, then combine the results
reg [2:0] pos_cnt;
reg pos_out;
reg [2:0] neg_cnt;
reg neg_out;

// Positive edge counter
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pos_cnt <= 0;
        pos_out <= 0;
    end else begin
        if(pos_cnt == N-1) begin
            pos_cnt <= 0;
            pos_out <= ~pos_out;
        end else begin
            pos_cnt <= pos_cnt + 1;
        end
    end
end

// Negative edge counter
always @(negedge clk or negedge rst_n) begin
    if(!rst_n) begin
        neg_cnt <= 0;
        neg_out <= 0;
    end else begin
        if(neg_cnt == N-1) begin
            neg_cnt <= 0;
            neg_out <= ~neg_out;
        end else begin
            neg_cnt <= neg_cnt + 1;
        end
    end
end

// Output generation
assign clk_out = pos_out ^ neg_out;
endmodule