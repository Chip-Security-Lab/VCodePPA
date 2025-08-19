//SystemVerilog
module ITRC_PriorityEncoder #(
    parameter WIDTH = 8,
    parameter [WIDTH*4-1:0] PRIORITY_LUT = 32'h01234567
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_src,
    output reg [3:0] highest_id
);

    wire [3:0] priority_values [WIDTH-1:0];
    wire [3:0] selected_priority;
    wire [3:0] selected_id;

    // Priority value extractor
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : PRIORITY_EXTRACT
            assign priority_values[i] = (PRIORITY_LUT >> (i*4)) & 4'hF;
        end
    endgenerate

    // Priority comparator
    PriorityComparator #(
        .WIDTH(WIDTH)
    ) u_priority_comparator (
        .int_src(int_src),
        .priority_values(priority_values),
        .selected_priority(selected_priority),
        .selected_id(selected_id)
    );

    // Output register
    always @(posedge clk) begin
        if (!rst_n) begin
            highest_id <= 0;
        end else begin
            highest_id <= selected_id;
        end
    end

endmodule

module PriorityComparator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] int_src,
    input [3:0] priority_values [WIDTH-1:0],
    output reg [3:0] selected_priority,
    output reg [3:0] selected_id
);

    wire [3:0] masked_priorities [WIDTH-1:0];
    wire [3:0] max_priority;
    wire [3:0] max_id;

    // Mask priorities with interrupt sources
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : MASK_PRIORITIES
            assign masked_priorities[i] = int_src[i] ? priority_values[i] : 4'h0;
        end
    endgenerate

    // Find maximum priority using parallel comparison
    wire [3:0] stage1_pri [WIDTH/2-1:0];
    wire [3:0] stage1_id [WIDTH/2-1:0];
    wire [3:0] stage2_pri [WIDTH/4-1:0];
    wire [3:0] stage2_id [WIDTH/4-1:0];
    wire [3:0] stage3_pri [WIDTH/8-1:0];
    wire [3:0] stage3_id [WIDTH/8-1:0];

    // First stage comparison
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin : STAGE1
            assign {stage1_pri[i], stage1_id[i]} = 
                (masked_priorities[2*i] >= masked_priorities[2*i+1]) ? 
                {masked_priorities[2*i], 4'(2*i)} : 
                {masked_priorities[2*i+1], 4'(2*i+1)};
        end
    endgenerate

    // Second stage comparison
    generate
        for (i = 0; i < WIDTH/4; i = i + 1) begin : STAGE2
            assign {stage2_pri[i], stage2_id[i]} = 
                (stage1_pri[2*i] >= stage1_pri[2*i+1]) ? 
                {stage1_pri[2*i], stage1_id[2*i]} : 
                {stage1_pri[2*i+1], stage1_id[2*i+1]};
        end
    endgenerate

    // Third stage comparison
    generate
        for (i = 0; i < WIDTH/8; i = i + 1) begin : STAGE3
            assign {stage3_pri[i], stage3_id[i]} = 
                (stage2_pri[2*i] >= stage2_pri[2*i+1]) ? 
                {stage2_pri[2*i], stage2_id[2*i]} : 
                {stage2_pri[2*i+1], stage2_id[2*i+1]};
        end
    endgenerate

    // Final comparison
    assign {selected_priority, selected_id} = 
        (stage3_pri[0] >= stage3_pri[1]) ? 
        {stage3_pri[0], stage3_id[0]} : 
        {stage3_pri[1], stage3_id[1]};

endmodule