//SystemVerilog
// Top level module
module dual_clock_comparator(
    input clk_a,
    input rst_a, 
    input [7:0] data_a,
    input req_a,
    output reg ack_a,
    
    input clk_b,
    input rst_b,
    input [7:0] data_b,
    output reg match_b,
    output reg valid_b
);

    wire ack_b;
    wire ack_b_sync2;
    wire req_edge_det;
    wire [7:0] data_a_sync2;
    wire req_a_sync2;
    wire req_a_sync3;

    // Clock domain A control
    clock_domain_a_ctrl u_clock_domain_a_ctrl(
        .clk_a(clk_a),
        .rst_a(rst_a),
        .ack_b_sync2(ack_b_sync2),
        .ack_a(ack_a)
    );

    // Clock domain B synchronizer
    clock_domain_b_sync u_clock_domain_b_sync(
        .clk_b(clk_b),
        .rst_b(rst_b),
        .data_a(data_a),
        .req_a(req_a),
        .data_a_sync2(data_a_sync2),
        .req_a_sync2(req_a_sync2),
        .req_a_sync3(req_a_sync3),
        .req_edge_det(req_edge_det)
    );

    // Comparison logic
    comparison_logic u_comparison_logic(
        .clk_b(clk_b),
        .rst_b(rst_b),
        .data_a_sync2(data_a_sync2),
        .data_b(data_b),
        .req_edge_det(req_edge_det),
        .req_a_sync2(req_a_sync2),
        .req_a_sync3(req_a_sync3),
        .match_b(match_b),
        .valid_b(valid_b),
        .ack_b(ack_b)
    );

    // Clock domain A synchronizer
    clock_domain_a_sync u_clock_domain_a_sync(
        .clk_a(clk_a),
        .rst_a(rst_a),
        .ack_b(ack_b),
        .ack_b_sync2(ack_b_sync2)
    );

endmodule

// Clock domain A control module
module clock_domain_a_ctrl(
    input clk_a,
    input rst_a,
    input ack_b_sync2,
    output reg ack_a
);

    always @(posedge clk_a or posedge rst_a) begin
        if (rst_a) begin
            ack_a <= 1'b0;
        end else begin
            ack_a <= ack_b_sync2;
        end
    end

endmodule

// Clock domain B synchronizer module
module clock_domain_b_sync(
    input clk_b,
    input rst_b,
    input [7:0] data_a,
    input req_a,
    output reg [7:0] data_a_sync2,
    output reg req_a_sync2,
    output reg req_a_sync3,
    output reg req_edge_det
);

    reg [7:0] data_a_sync1;
    reg req_a_sync1;

    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            data_a_sync1 <= 8'h00;
            data_a_sync2 <= 8'h00;
            req_a_sync1 <= 1'b0;
            req_a_sync2 <= 1'b0;
            req_a_sync3 <= 1'b0;
            req_edge_det <= 1'b0;
        end else begin
            data_a_sync1 <= data_a;
            data_a_sync2 <= data_a_sync1;
            req_a_sync1 <= req_a;
            req_a_sync2 <= req_a_sync1;
            req_a_sync3 <= req_a_sync2;
            req_edge_det <= req_a_sync2 & ~req_a_sync3;
        end
    end

endmodule

// Comparison logic module
module comparison_logic(
    input clk_b,
    input rst_b,
    input [7:0] data_a_sync2,
    input [7:0] data_b,
    input req_edge_det,
    input req_a_sync2,
    input req_a_sync3,
    output reg match_b,
    output reg valid_b,
    output reg ack_b
);

    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            match_b <= 1'b0;
            valid_b <= 1'b0;
            ack_b <= 1'b0;
        end else begin
            if (req_edge_det) begin
                match_b <= (data_a_sync2 == data_b);
                valid_b <= 1'b1;
                ack_b <= 1'b1;
            end else if (req_a_sync2 == 1'b0 && req_a_sync3 == 1'b1) begin
                valid_b <= 1'b0;
                ack_b <= 1'b0;
            end
        end
    end

endmodule

// Clock domain A synchronizer module
module clock_domain_a_sync(
    input clk_a,
    input rst_a,
    input ack_b,
    output reg ack_b_sync2
);

    reg ack_b_sync1;

    always @(posedge clk_a or posedge rst_a) begin
        if (rst_a) begin
            ack_b_sync1 <= 1'b0;
            ack_b_sync2 <= 1'b0;
        end else begin
            ack_b_sync1 <= ack_b;
            ack_b_sync2 <= ack_b_sync1;
        end
    end

endmodule