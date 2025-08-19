//SystemVerilog
module dual_clock_priority_comp #(parameter WIDTH = 8)(
    input clk_a, clk_b, rst_n,
    input [WIDTH-1:0] data_in,
    input valid_in,
    output reg [$clog2(WIDTH)-1:0] priority_a,
    output reg [$clog2(WIDTH)-1:0] priority_b,
    output reg valid_out_a,
    output reg valid_out_b
);

    // Optimized priority calculation (combinational) using $clog2 and priority encoder logic
    wire [$clog2(WIDTH)-1:0] priority_stage1;

    // Use $clog2(WIDTH) bits for the output index
    // This can be implemented efficiently with priority encoder logic in hardware
    // For example, using a chain of OR gates and AND gates, or a dedicated IP
    // The exact hardware implementation depends on the synthesis tool

    // Example implementation using a generate block (conceptual, synthesis tool handles optimization)
    // This is functionally equivalent to the original loop but hints at hardware structure
    wire [WIDTH-1:0] data_in_rev;
    wire [WIDTH-1:0] priority_mask;
    wire [WIDTH-1:0] priority_one_hot;

    generate
        for (genvar i = 0; i < WIDTH; i++) begin : reverse_data
            assign data_in_rev[i] = data_in[WIDTH - 1 - i];
        end
    endgenerate

    assign priority_mask[0] = data_in_rev[0];
    generate
        for (genvar i = 1; i < WIDTH; i++) begin : generate_mask
            assign priority_mask[i] = data_in_rev[i] | priority_mask[i-1];
        end
    endgenerate

    assign priority_one_hot[0] = priority_mask[0] & ~priority_mask[1]; // Only bit 0 if bit 1 is 0
    generate
        for (genvar i = 1; i < WIDTH - 1; i++) begin : generate_one_hot
            assign priority_one_hot[i] = priority_mask[i] & ~priority_mask[i+1];
        end
    endgenerate
    assign priority_one_hot[WIDTH-1] = priority_mask[WIDTH-1]; // Highest bit is set if mask is set

    // Convert one-hot to binary index
    wire [$clog2(WIDTH)-1:0] priority_binary;
    assign priority_binary = $clog2(WIDTH)'(0); // Default to 0 if no bit is set
    generate
        for (genvar i = 0; i < WIDTH; i++) begin : one_hot_to_binary
            if (i > 0) begin // Avoid multi-driver issue for bit 0
                assign priority_binary = priority_one_hot[i] ? $clog2(WIDTH)'(WIDTH - 1 - i) : priority_binary;
            end else begin
                 assign priority_binary = priority_one_hot[i] ? $clog2(WIDTH)'(WIDTH - 1 - i) : $clog2(WIDTH)'(0); // Handle bit 0
            end
        end
    endgenerate


    assign priority_stage1 = priority_binary;


    // Stage 1 registers (clk_a domain)
    reg [$clog2(WIDTH)-1:0] priority_stage1_reg_a;
    reg valid_stage1_reg_a;

    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) begin
            priority_stage1_reg_a <= 0;
            valid_stage1_reg_a <= 0;
        end else begin
            priority_stage1_reg_a <= priority_stage1;
            valid_stage1_reg_a <= valid_in;
        end
    end

    // Output Stage (clk_a domain)
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) begin
            priority_a <= 0;
            valid_out_a <= 0;
        end else begin
            priority_a <= priority_stage1_reg_a;
            valid_out_a <= valid_stage1_reg_a;
        end
    end

    // Stage 1 registers (clk_b domain - synchronization)
    reg [WIDTH-1:0] data_in_sync_b;
    reg valid_in_sync_b;

    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            data_in_sync_b <= 0;
            valid_in_sync_b <= 0;
        end else begin
            data_in_sync_b <= data_in;
            valid_in_sync_b <= valid_in;
        end
    end

    // Stage 2: Priority calculation (clk_b domain) - Reusing optimized logic
    wire [$clog2(WIDTH)-1:0] priority_stage2;

    wire [WIDTH-1:0] data_in_sync_b_rev;
    wire [WIDTH-1:0] priority_mask_b;
    wire [WIDTH-1:0] priority_one_hot_b;

    generate
        for (genvar i = 0; i < WIDTH; i++) begin : reverse_data_b
            assign data_in_sync_b_rev[i] = data_in_sync_b[WIDTH - 1 - i];
        end
    endgenerate

    assign priority_mask_b[0] = data_in_sync_b_rev[0];
    generate
        for (genvar i = 1; i < WIDTH; i++) begin : generate_mask_b
            assign priority_mask_b[i] = data_in_sync_b_rev[i] | priority_mask_b[i-1];
        end
    endgenerate

    assign priority_one_hot_b[0] = priority_mask_b[0] & ~priority_mask_b[1];
    generate
        for (genvar i = 1; i < WIDTH - 1; i++) begin : generate_one_hot_b
            assign priority_one_hot_b[i] = priority_mask_b[i] & ~priority_mask_b[i+1];
        end
    endgenerate
    assign priority_one_hot_b[WIDTH-1] = priority_mask_b[WIDTH-1];

    wire [$clog2(WIDTH)-1:0] priority_binary_b;
    assign priority_binary_b = $clog2(WIDTH)'(0);
     generate
        for (genvar i = 0; i < WIDTH; i++) begin : one_hot_to_binary_b
            if (i > 0) begin
                assign priority_binary_b = priority_one_hot_b[i] ? $clog2(WIDTH)'(WIDTH - 1 - i) : priority_binary_b;
            end else begin
                 assign priority_binary_b = priority_one_hot_b[i] ? $clog2(WIDTH)'(WIDTH - 1 - i) : $clog2(WIDTH)'(0);
            end
        end
    endgenerate

    assign priority_stage2 = priority_binary_b;


    // Stage 2 registers (clk_b domain)
    reg [$clog2(WIDTH)-1:0] priority_stage2_reg_b;
    reg valid_stage2_reg_b;

    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            priority_stage2_reg_b <= 0;
            valid_stage2_reg_b <= 0;
        end else begin
            priority_stage2_reg_b <= priority_stage2;
            valid_stage2_reg_b <= valid_in_sync_b;
        end
    end

    // Output Stage (clk_b domain)
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            priority_b <= 0;
            valid_out_b <= 0;
        end else begin
            priority_b <= priority_stage2_reg_b;
            valid_out_b <= valid_stage2_reg_b;
        end
    end

endmodule