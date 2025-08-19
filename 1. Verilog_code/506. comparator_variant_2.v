module comparator_top(
    input clk,
    input rst_n,
    input [3:0] a, b,
    output reg gt, eq, lt
);
    // Pipeline registers
    reg [3:0] a_pipe1, b_pipe1;
    reg [3:0] a_pipe2, b_pipe2;
    reg gt_pipe, eq_pipe, lt_pipe;
    
    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_pipe1 <= 4'b0;
            b_pipe1 <= 4'b0;
        end else begin
            a_pipe1 <= a;
            b_pipe1 <= b;
        end
    end
    
    // Stage 2: Comparison logic
    wire gt_wire, eq_wire, lt_wire;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_pipe2 <= 4'b0;
            b_pipe2 <= 4'b0;
        end else begin
            a_pipe2 <= a_pipe1;
            b_pipe2 <= b_pipe1;
        end
    end
    
    // Comparison logic with reduced fanout
    assign gt_wire = (a_pipe2 > b_pipe2);
    assign eq_wire = (a_pipe2 == b_pipe2);
    assign lt_wire = (a_pipe2 < b_pipe2);
    
    // Stage 3: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gt_pipe <= 1'b0;
            eq_pipe <= 1'b0;
            lt_pipe <= 1'b0;
        end else begin
            gt_pipe <= gt_wire;
            eq_pipe <= eq_wire;
            lt_pipe <= lt_wire;
        end
    end
    
    // Final output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gt <= 1'b0;
            eq <= 1'b0;
            lt <= 1'b0;
        end else begin
            gt <= gt_pipe;
            eq <= eq_pipe;
            lt <= lt_pipe;
        end
    end
endmodule