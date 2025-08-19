//SystemVerilog
module multiplier_comb (
    input clk,
    input rst_n,
    input req,
    input [7:0] a,
    input [7:0] b,
    output reg ack,
    output reg [15:0] product
);

    // Control signals
    wire req_edge;
    wire [15:0] mult_result;
    
    // Instantiate edge detector
    edge_detector u_edge_detector (
        .clk(clk),
        .rst_n(rst_n),
        .signal_in(req),
        .edge_out(req_edge)
    );
    
    // Instantiate multiplier
    multiplier u_multiplier (
        .a(a),
        .b(b),
        .product(mult_result)
    );
    
    // Instantiate output controller
    output_controller u_output_controller (
        .clk(clk),
        .rst_n(rst_n),
        .req_edge(req_edge),
        .mult_result(mult_result),
        .ack(ack),
        .product(product)
    );

endmodule

module edge_detector (
    input clk,
    input rst_n,
    input signal_in,
    output reg edge_out
);
    
    reg signal_d;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_d <= 1'b0;
            edge_out <= 1'b0;
        end else begin
            signal_d <= signal_in;
            edge_out <= signal_in && !signal_d;
        end
    end
    
endmodule

module multiplier (
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] product
);
    
    always @(*) begin
        product = a * b;
    end
    
endmodule

module output_controller (
    input clk,
    input rst_n,
    input req_edge,
    input [15:0] mult_result,
    output reg ack,
    output reg [15:0] product
);
    
    reg [15:0] product_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ack <= 1'b0;
            product_reg <= 16'b0;
            product <= 16'b0;
        end else begin
            if (req_edge) begin
                product_reg <= mult_result;
                ack <= 1'b1;
            end else if (ack) begin
                product <= product_reg;
                ack <= 1'b0;
            end
        end
    end
    
endmodule