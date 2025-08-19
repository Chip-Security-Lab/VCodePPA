//SystemVerilog
module self_checking_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_index,
    output reg valid,
    output reg error
);

    // Pipeline stage 1 registers
    reg [WIDTH-1:0] data_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [$clog2(WIDTH)-1:0] expected_priority_stage2;
    reg valid_stage2;
    reg [WIDTH-1:0] data_stage2;
    
    // Pipeline stage 3 registers
    reg [$clog2(WIDTH)-1:0] expected_priority_stage3;
    reg valid_stage3;
    reg [WIDTH-1:0] priority_mask_stage3;

    // Pre-compute priority detection logic
    function automatic [$clog2(WIDTH)-1:0] find_priority;
        input [WIDTH-1:0] data;
        reg [$clog2(WIDTH)-1:0] index;
    begin
        index = 0;
        for (int i = 0; i < WIDTH; i = i + 1)
            if (data[i]) index = i[$clog2(WIDTH)-1:0];
        find_priority = index;
    end
    endfunction

    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) data_stage1 <= 0;
        else data_stage1 <= data_in;
    end

    // Stage 1: Valid detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) valid_stage1 <= 0;
        else valid_stage1 <= |data_in;
    end

    // Stage 2: Priority calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) expected_priority_stage2 <= 0;
        else expected_priority_stage2 <= find_priority(data_stage1);
    end

    // Stage 2: Data and valid propagation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 0;
            data_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
            data_stage2 <= data_stage1;
        end
    end

    // Stage 3: Priority propagation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) expected_priority_stage3 <= 0;
        else expected_priority_stage3 <= expected_priority_stage2;
    end

    // Stage 3: Valid propagation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) valid_stage3 <= 0;
        else valid_stage3 <= valid_stage2;
    end

    // Stage 3: Mask generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) priority_mask_stage3 <= 0;
        else priority_mask_stage3 <= valid_stage2 ? (1'b1 << expected_priority_stage2) : 0;
    end

    // Stage 4: Priority index output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) priority_index <= 0;
        else priority_index <= expected_priority_stage3;
    end

    // Stage 4: Valid output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) valid <= 0;
        else valid <= valid_stage3;
    end

    // Stage 4: Error detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) error <= 0;
        else error <= valid_stage3 & ~data_stage2[expected_priority_stage3];
    end

endmodule