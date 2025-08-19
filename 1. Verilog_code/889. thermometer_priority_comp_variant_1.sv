//SystemVerilog
//IEEE 1364-2005 Verilog
module thermometer_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] thermometer_out,
    output reg [$clog2(WIDTH)-1:0] priority_pos
);
    reg [WIDTH-1:0] data_in_reg;
    wire [$clog2(WIDTH)-1:0] priority_pos_next;
    wire [WIDTH-1:0] thermometer_out_next;
    
    // Parallel Prefix Subtractor signals
    wire [WIDTH-1:0] g_signals, p_signals;
    wire [WIDTH-1:0] c_signals;
    wire [WIDTH:0] borrow;
    wire [WIDTH-1:0] diff;
    
    // Encoder signals for priority position
    wire [WIDTH-1:0] one_hot;

    // Input register stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 0;
        end else begin
            data_in_reg <= data_in;
        end
    end

    // Parallel Prefix Subtractor implementation
    // Generate and propagate signals
    assign g_signals = ~data_in_reg;
    assign p_signals = 0; // For subtractor, propagate is 0
    
    // First level of prefix computation (borrow generation)
    assign borrow[0] = 1'b0; // No initial borrow
    
    // Prefix tree for borrow computation (log2 stages)
    generate
        genvar i, j, k;
        
        // Stage 1: Generate prefix pairs
        for(i = 0; i < WIDTH; i = i + 1) begin: stage1
            assign c_signals[i] = g_signals[i];
            assign borrow[i+1] = c_signals[i];
        end
        
        // Compute difference
        for(k = 0; k < WIDTH; k = k + 1) begin: diff_compute
            assign diff[k] = data_in_reg[k] ^ borrow[k];
        end
        
        // Priority encoder using one-hot encoding
        assign one_hot[0] = diff[0];
        for(j = 1; j < WIDTH; j = j + 1) begin: one_hot_gen
            assign one_hot[j] = diff[j] & ~(|diff[j-1:0]);
        end
    endgenerate
    
    // Priority position encoder (one-hot to binary)
    parallel_encoder #(.WIDTH(WIDTH)) encoder_inst (
        .one_hot(one_hot),
        .binary(priority_pos_next)
    );
    
    // Generate thermometer code from priority position
    generate_thermometer #(.WIDTH(WIDTH)) therm_gen (
        .priority_pos(priority_pos_next),
        .thermometer(thermometer_out_next)
    );

    // Output register for priority position
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_pos <= 0;
        end else begin
            priority_pos <= priority_pos_next;
        end
    end

    // Output register for thermometer code
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            thermometer_out <= 0;
        end else begin
            thermometer_out <= thermometer_out_next;
        end
    end
endmodule

// One-hot to binary encoder
module parallel_encoder #(parameter WIDTH = 8)(
    input [WIDTH-1:0] one_hot,
    output [$clog2(WIDTH)-1:0] binary
);
    genvar i, j;
    generate
        for(i = 0; i < $clog2(WIDTH); i = i + 1) begin: binary_bits
            wire [WIDTH-1:0] tmp_mask;
            for(j = 0; j < WIDTH; j = j + 1) begin: bit_mask
                assign tmp_mask[j] = j[i] ? one_hot[j] : 1'b0;
            end
            assign binary[i] = |tmp_mask;
        end
    endgenerate
endmodule

// Priority position to thermometer code converter
module generate_thermometer #(parameter WIDTH = 8)(
    input [$clog2(WIDTH)-1:0] priority_pos,
    output [WIDTH-1:0] thermometer
);
    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin: therm_gen
            assign thermometer[i] = (i <= priority_pos) ? 1'b1 : 1'b0;
        end
    endgenerate
endmodule