//SystemVerilog
// SystemVerilog - IEEE 1364-2005
module error_arbiter #(parameter WIDTH=4) (
    input wire clk, rst_n,
    input wire [WIDTH-1:0] req_i,
    input wire error_en,
    output reg [WIDTH-1:0] grant_o
);

    // Pipeline stage 1: Calculate req_neg and bitwise AND
    reg [WIDTH-1:0] req_delayed;
    reg [WIDTH-1:0] req_neg_delayed;
    reg error_en_delayed;
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            req_delayed <= {WIDTH{1'b0}};
            req_neg_delayed <= {WIDTH{1'b0}};
            error_en_delayed <= 1'b0;
        end else begin
            req_delayed <= req_i;
            req_neg_delayed <= ~req_i + 1'b1;
            error_en_delayed <= error_en;
        end
    end
    
    // Pipeline stage 2: Final grant calculation
    wire [WIDTH-1:0] normal_grant_pipeline;
    assign normal_grant_pipeline = req_delayed & req_neg_delayed;
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            grant_o <= {WIDTH{1'b0}};
        end else begin
            grant_o <= error_en_delayed ? {WIDTH{1'b1}} : normal_grant_pipeline;
        end
    end

endmodule