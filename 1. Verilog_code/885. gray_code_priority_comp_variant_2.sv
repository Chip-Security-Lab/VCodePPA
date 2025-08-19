//SystemVerilog
module gray_code_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] binary_priority,
    output reg [$clog2(WIDTH)-1:0] gray_priority,
    output reg valid
);
    // Internal signals
    wire [$clog2(WIDTH)-1:0] next_binary_priority;
    wire next_valid;
    
    // Binary-to-Gray conversion function
    function [$clog2(WIDTH)-1:0] bin2gray;
        input [$clog2(WIDTH)-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction
    
    // Combinational logic for priority detection
    assign next_valid = |data_in;
    
    // Priority encoder logic in separate module
    priority_encoder #(
        .WIDTH(WIDTH)
    ) priority_enc_inst (
        .data_in(data_in),
        .binary_priority(next_binary_priority)
    );
    
    // Reset and register update logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid <= 1'b0;
            binary_priority <= {$clog2(WIDTH){1'b0}};
            gray_priority <= {$clog2(WIDTH){1'b0}};
        end else begin
            valid <= next_valid;
            binary_priority <= next_binary_priority;
            gray_priority <= bin2gray(next_binary_priority);
        end
    end
endmodule

// Priority encoder module - extracts highest priority bit position
module priority_encoder #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] binary_priority
);
    // Optimized priority encoder using parallel prefix computation
    wire [WIDTH-1:0] mask;
    wire [WIDTH-1:0] masked_data;
    
    // Generate mask for parallel prefix computation
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : mask_gen
            assign mask[i] = (i == 0) ? 1'b1 : mask[i-1] & ~data_in[i-1];
        end
    endgenerate
    
    // Apply mask to data
    assign masked_data = data_in & mask;
    
    // Find highest priority bit using parallel prefix
    always @(*) begin
        binary_priority = {$clog2(WIDTH){1'b0}};
        for (int i = 0; i < WIDTH; i = i + 1) begin
            if (masked_data[i]) binary_priority = i[$clog2(WIDTH)-1:0];
        end
    end
endmodule