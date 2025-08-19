//SystemVerilog
module boundary_check_comp #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data,
    input wire [WIDTH-1:0] upper_bound,
    input wire [WIDTH-1:0] lower_bound,
    output reg [$clog2(WIDTH)-1:0] priority_pos,
    output reg in_bounds,
    output reg valid
);

    // Stage 1: Boundary checking pipeline registers
    reg [WIDTH-1:0] data_r;
    reg [WIDTH-1:0] upper_bound_r;
    reg [WIDTH-1:0] lower_bound_r;
    reg bounds_check_valid;
    reg in_bounds_stage1;
    
    // Stage 2: Data masking pipeline registers
    reg [WIDTH-1:0] masked_data;
    reg bounds_check_valid_r;
    reg in_bounds_stage2;
    
    // Stage 3: Priority encoding pipeline signals
    reg [$clog2(WIDTH)-1:0] priority_encoder_output;
    reg priority_valid;

    // Parallel prefix subtractor signals
    wire [WIDTH-1:0] lower_diff;
    wire [WIDTH-1:0] upper_diff;
    wire [WIDTH-1:0] lower_borrow;
    wire [WIDTH-1:0] upper_borrow;
    wire [WIDTH-1:0] lower_borrow_propagate;
    wire [WIDTH-1:0] upper_borrow_propagate;
    wire [WIDTH-1:0] lower_borrow_generate;
    wire [WIDTH-1:0] upper_borrow_generate;

    // Parallel prefix subtractor for lower bound
    generate
        genvar i;
        for (i = 0; i < WIDTH; i = i + 1) begin : lower_sub
            assign lower_borrow_generate[i] = ~data[i] & lower_bound[i];
            assign lower_borrow_propagate[i] = data[i] ^ lower_bound[i];
            assign lower_diff[i] = data[i] ^ lower_bound[i] ^ lower_borrow[i];
        end
    endgenerate

    // Parallel prefix subtractor for upper bound
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : upper_sub
            assign upper_borrow_generate[i] = upper_bound[i] & ~data[i];
            assign upper_borrow_propagate[i] = upper_bound[i] ^ data[i];
            assign upper_diff[i] = upper_bound[i] ^ data[i] ^ upper_borrow[i];
        end
    endgenerate

    // Parallel prefix tree for borrow computation
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : borrow_tree
            if (i == 0) begin
                assign lower_borrow[i] = lower_borrow_generate[i];
                assign upper_borrow[i] = upper_borrow_generate[i];
            end else begin
                assign lower_borrow[i] = lower_borrow_generate[i] | 
                                      (lower_borrow_propagate[i] & lower_borrow[i-1]);
                assign upper_borrow[i] = upper_borrow_generate[i] | 
                                      (upper_borrow_propagate[i] & upper_borrow[i-1]);
            end
        end
    endgenerate

    // Stage 1: Boundary checking logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_r <= 0;
            upper_bound_r <= 0;
            lower_bound_r <= 0;
            in_bounds_stage1 <= 0;
            bounds_check_valid <= 0;
        end else begin
            data_r <= data;
            upper_bound_r <= upper_bound;
            lower_bound_r <= lower_bound;
            
            // Use parallel prefix subtractor results
            in_bounds_stage1 <= ~lower_borrow[WIDTH-1] && ~upper_borrow[WIDTH-1];
            bounds_check_valid <= 1'b1;
        end
    end

    // ... existing code for Stage 2 and Stage 3 ...
    
    // Stage 2: Data masking logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_data <= 0;
            bounds_check_valid_r <= 0;
            in_bounds_stage2 <= 0;
        end else begin
            bounds_check_valid_r <= bounds_check_valid;
            in_bounds_stage2 <= in_bounds_stage1;
            masked_data <= in_bounds_stage1 ? data_r : {WIDTH{1'b0}};
        end
    end
    
    // Stage 3: Priority encoding logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_encoder_output <= 0;
            priority_valid <= 0;
        end else begin
            priority_valid <= |masked_data && bounds_check_valid_r;
            priority_encoder_output <= 0;
            for (integer i = WIDTH-1; i >= 0; i = i - 1) begin
                if (masked_data[i]) begin
                    priority_encoder_output <= i[$clog2(WIDTH)-1:0];
                end
            end
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_pos <= 0;
            in_bounds <= 0;
            valid <= 0;
        end else begin
            priority_pos <= priority_encoder_output;
            in_bounds <= in_bounds_stage2;
            valid <= priority_valid;
        end
    end
    
endmodule