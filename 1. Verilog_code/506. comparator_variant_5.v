module comparator_pipelined(
    input wire clk,
    input wire rst_n,
    input wire [3:0] a,
    input wire [3:0] b,
    output reg gt,
    output reg eq,
    output reg lt
);

    // Pipeline stage 1: Input registers
    reg [3:0] a_reg;
    reg [3:0] b_reg;
    
    // Pipeline stage 2: Comparison logic
    wire [3:0] diff;
    wire gt_wire, eq_wire, lt_wire;
    
    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0;
            b_reg <= 4'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end
    
    // Stage 2: Optimized comparison logic
    assign diff = a_reg - b_reg;
    assign gt_wire = ~diff[3] & |diff[2:0];
    assign eq_wire = ~|diff;
    assign lt_wire = diff[3];
    
    // Stage 3: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gt <= 1'b0;
            eq <= 1'b0;
            lt <= 1'b0;
        end else begin
            gt <= gt_wire;
            eq <= eq_wire;
            lt <= lt_wire;
        end
    end

endmodule