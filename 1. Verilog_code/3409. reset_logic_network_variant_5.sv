//SystemVerilog - IEEE 1364-2005
// Top level module that instantiates the reset processing submodules
module reset_logic_network (
    input  wire [3:0] reset_sources,
    input  wire [3:0] config_bits,
    output reg  [3:0] reset_outputs
);
    // Internal signals for connecting the submodules
    wire reset_out_0, reset_out_1, reset_out_2, reset_out_3;
    
    // Assign processed outputs to the output register
    always @(*) begin
        reset_outputs[0] = reset_out_0;
        reset_outputs[1] = reset_out_1;
        reset_outputs[2] = reset_out_2;
        reset_outputs[3] = reset_out_3;
    end
    
    // Instantiate reset processing modules
    reset_processor #(
        .SOURCE_IDX_A(0),
        .SOURCE_IDX_B(1)
    ) proc_0 (
        .reset_sources(reset_sources),
        .config_bit(config_bits[0]),
        .reset_out(reset_out_0)
    );
    
    reset_processor #(
        .SOURCE_IDX_A(1),
        .SOURCE_IDX_B(2)
    ) proc_1 (
        .reset_sources(reset_sources),
        .config_bit(config_bits[1]),
        .reset_out(reset_out_1)
    );
    
    reset_processor #(
        .SOURCE_IDX_A(2),
        .SOURCE_IDX_B(3)
    ) proc_2 (
        .reset_sources(reset_sources),
        .config_bit(config_bits[2]),
        .reset_out(reset_out_2)
    );
    
    reset_processor #(
        .SOURCE_IDX_A(3),
        .SOURCE_IDX_B(0)
    ) proc_3 (
        .reset_sources(reset_sources),
        .config_bit(config_bits[3]),
        .reset_out(reset_out_3)
    );
    
endmodule

// Parameterized reset processing submodule
// Handles a single reset output based on two configurable reset sources
module reset_processor #(
    parameter SOURCE_IDX_A = 0,
    parameter SOURCE_IDX_B = 0
)(
    input  wire [3:0] reset_sources,
    input  wire       config_bit,
    output wire       reset_out
);
    // Internal signals for better readability and timing closure
    wire reset_src_a;
    wire reset_src_b;
    reg  result;
    
    // Select the specific reset sources based on parameters
    assign reset_src_a = reset_sources[SOURCE_IDX_A];
    assign reset_src_b = reset_sources[SOURCE_IDX_B];
    
    // Process reset signals based on configuration
    always @(*) begin
        if (config_bit)
            result = reset_src_a & reset_src_b; // AND operation when config bit is set
        else
            result = reset_src_a | reset_src_b; // OR operation when config bit is clear
    end
    
    // Drive the output
    assign reset_out = result;
    
endmodule