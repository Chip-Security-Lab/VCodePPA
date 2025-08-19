//SystemVerilog
//=====================================================================
// Top module for dynamic S-box AES implementation
//=====================================================================
module dynamic_sbox_aes (
    input  wire       clk,
    input  wire       gen_sbox,
    input  wire [7:0] sbox_in,
    output wire [7:0] sbox_out
);

    // Internal connections between submodules
    wire [7:0] sbox_value [0:255];
    wire [7:0] sbox_in_reg;

    // Register input data first to improve timing
    register_stage input_reg (
        .clk(clk),
        .data_in(sbox_in),
        .data_out(sbox_in_reg)
    );

    // Instantiate S-box generator submodule
    sbox_generator sbox_gen_inst (
        .clk(clk),
        .gen_sbox(gen_sbox),
        .sbox_values(sbox_value)
    );

    // Instantiate S-box lookup submodule with pipelining
    sbox_lookup sbox_lookup_inst (
        .clk(clk),
        .sbox_in(sbox_in_reg),
        .sbox_mem(sbox_value),
        .sbox_out(sbox_out)
    );

endmodule

//=====================================================================
// Simple register stage module
//=====================================================================
module register_stage (
    input  wire       clk,
    input  wire [7:0] data_in,
    output reg  [7:0] data_out
);

    always @(posedge clk) begin
        data_out <= data_in;
    end

endmodule

//=====================================================================
// S-box generator module with optimized critical path
//=====================================================================
module sbox_generator (
    input  wire       clk,
    input  wire       gen_sbox,
    output reg  [7:0] sbox_values [0:255]
);

    // Pre-compute the polynomial multiplication values to reduce combinational delay
    reg [7:0] mult_values [0:255];
    // Pipeline registers for computation stages
    reg [7:0] mult_stage [0:255];
    reg gen_sbox_r;
    integer i;
    
    // Initialize the multiplication values first
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            mult_values[i] = (i * 8'h1B);
        end
    end
    
    // Register the control signal
    always @(posedge clk) begin
        gen_sbox_r <= gen_sbox;
    end
    
    // First pipeline stage: multiplication operation
    always @(posedge clk) begin
        if (gen_sbox) begin
            for (i = 0; i < 256; i = i + 1) begin
                mult_stage[i] <= mult_values[i];
            end
        end
    end
    
    // Second pipeline stage: final XOR operation
    always @(posedge clk) begin
        if (gen_sbox_r) begin
            for (i = 0; i < 256; i = i + 1) begin
                sbox_values[i] <= mult_stage[i] ^ 8'h63;
            end
        end
    end

endmodule

//=====================================================================
// S-box lookup module with pipelined timing
//=====================================================================
module sbox_lookup (
    input  wire       clk,
    input  wire [7:0] sbox_in,
    input  wire [7:0] sbox_mem [0:255],
    output reg  [7:0] sbox_out
);

    // Split the lookup process into pipeline stages
    reg  [7:0] sbox_in_stage1;
    wire [7:0] lookup_value;
    reg  [3:0] addr_high, addr_low;
    reg  [7:0] lookup_results [0:15];
    reg  [3:0] addr_low_r;
    
    // Stage 1: Register input and split address
    always @(posedge clk) begin
        sbox_in_stage1 <= sbox_in;
        addr_high <= sbox_in[7:4];
        addr_low <= sbox_in[3:0];
    end
    
    // Stage 2: Pre-select 16 possible values based on high address
    always @(posedge clk) begin
        for (int j = 0; j < 16; j = j + 1) begin
            lookup_results[j] <= sbox_mem[{addr_high, j[3:0]}];
        end
        addr_low_r <= addr_low;
    end
    
    // Stage 3: Final selection using low address
    always @(posedge clk) begin
        sbox_out <= lookup_results[addr_low_r];
    end

endmodule