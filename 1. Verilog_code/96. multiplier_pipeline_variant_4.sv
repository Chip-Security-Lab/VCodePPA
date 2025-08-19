//SystemVerilog
module multiplier_pipeline (
    input clk,
    input rst_n,
    input [7:0] a,
    input [7:0] b,
    input valid_in,
    output reg ready_in,
    output reg [15:0] product,
    output reg valid_out,
    input ready_out
);
    reg [15:0] p1, p2, p3;
    reg [7:0] a_reg, b_reg;
    reg valid_p1, valid_p2, valid_p3;
    reg ready_p1, ready_p2, ready_p3;
    
    // Input stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_p1 <= 1'b0;
            ready_in <= 1'b0;
        end else begin
            if (valid_in && ready_in) begin
                valid_p1 <= 1'b1;
            end else if (!valid_in || !ready_p1) begin
                valid_p1 <= 1'b0;
            end
            ready_in <= ready_p1;
        end
    end

    // Input registers moved after combinational logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
        end else if (valid_in && ready_in) begin
            a_reg <= a;
            b_reg <= b;
        end
    end
    
    // First pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p1 <= 16'b0;
            valid_p2 <= 1'b0;
            ready_p1 <= 1'b0;
        end else begin
            if (valid_p1 && ready_p1) begin
                p1 <= a_reg * b_reg;
                valid_p2 <= 1'b1;
            end else if (!valid_p1 || !ready_p2) begin
                valid_p2 <= 1'b0;
            end
            ready_p1 <= ready_p2;
        end
    end
    
    // Carry look-ahead adder signals for second pipeline stage
    wire [15:0] cla_p2_sum;
    wire [15:0] p2_addend = 16'd1;
    
    // Carry look-ahead adder for p2 = p1 + 1
    cla_16bit cla_stage2 (
        .a(p1),
        .b(p2_addend),
        .cin(1'b0),
        .sum(cla_p2_sum),
        .cout()
    );
    
    // Second pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p2 <= 16'b0;
            valid_p3 <= 1'b0;
            ready_p2 <= 1'b0;
        end else begin
            if (valid_p2 && ready_p2) begin
                p2 <= cla_p2_sum;
                valid_p3 <= 1'b1;
            end else if (!valid_p2 || !ready_p3) begin
                valid_p3 <= 1'b0;
            end
            ready_p2 <= ready_p3;
        end
    end
    
    // Carry look-ahead adder signals for third pipeline stage
    wire [15:0] cla_p3_sum;
    wire [15:0] p3_addend = 16'd1;
    
    // Carry look-ahead adder for p3 = p2 + 1
    cla_16bit cla_stage3 (
        .a(p2),
        .b(p3_addend),
        .cin(1'b0),
        .sum(cla_p3_sum),
        .cout()
    );
    
    // Third pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p3 <= 16'b0;
            valid_out <= 1'b0;
            ready_p3 <= 1'b0;
        end else begin
            if (valid_p3 && ready_p3) begin
                p3 <= cla_p3_sum;
                valid_out <= 1'b1;
            end else if (!valid_p3 || !ready_out) begin
                valid_out <= 1'b0;
            end
            ready_p3 <= ready_out;
        end
    end
    
    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 16'b0;
        end else if (valid_out && ready_out) begin
            product <= p3;
        end
    end
endmodule

module cla_16bit (
    input [15:0] a,
    input [15:0] b,
    input cin,
    output [15:0] sum,
    output cout
);
    wire [3:0] group_carry;
    
    cla_4bit cla0 (
        .a(a[3:0]),
        .b(b[3:0]),
        .cin(cin),
        .sum(sum[3:0]),
        .cout(group_carry[0])
    );
    
    cla_4bit cla1 (
        .a(a[7:4]),
        .b(b[7:4]),
        .cin(group_carry[0]),
        .sum(sum[7:4]),
        .cout(group_carry[1])
    );
    
    cla_4bit cla2 (
        .a(a[11:8]),
        .b(b[11:8]),
        .cin(group_carry[1]),
        .sum(sum[11:8]),
        .cout(group_carry[2])
    );
    
    cla_4bit cla3 (
        .a(a[15:12]),
        .b(b[15:12]),
        .cin(group_carry[2]),
        .sum(sum[15:12]),
        .cout(group_carry[3])
    );
    
    assign cout = group_carry[3];
endmodule

module cla_4bit (
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [3:0] p;
    wire [3:0] g;
    wire [4:0] c;
    
    assign p = a ^ b;
    assign g = a & b;
    
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    
    assign sum = p ^ {c[3:0]};
    assign cout = c[4];
endmodule