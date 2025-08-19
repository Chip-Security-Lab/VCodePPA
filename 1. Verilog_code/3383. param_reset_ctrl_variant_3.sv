//SystemVerilog
// Top level module with improved data flow architecture
module param_reset_ctrl #(
    parameter WIDTH = 4,
    parameter ACTIVE_HIGH = 1
)(
    input  wire            clk,         // Clock input for pipeline registers
    input  wire            reset_in,    // Input reset signal
    input  wire            enable,      // Enable signal
    output wire [WIDTH-1:0] reset_out   // Output reset vector
);
    // Pipeline stage signals
    reg             reset_in_reg;       // Register for input stabilization
    reg             normalized_reset_stage1; // First pipeline stage
    reg             normalized_reset_stage2; // Second pipeline stage
    reg             enable_reg;         // Registered enable signal
    reg [WIDTH-1:0] reset_out_internal; // Internal registered output

    // ===== STAGE 1: Input Registration =====
    always @(posedge clk) begin
        reset_in_reg <= reset_in;
        enable_reg <= enable;
    end

    // ===== STAGE 2: Reset Normalization =====
    wire normalized_reset_wire;
    
    // Convert reset to consistent polarity based on ACTIVE_HIGH parameter
    assign normalized_reset_wire = ACTIVE_HIGH ? reset_in_reg : ~reset_in_reg;
    
    always @(posedge clk) begin
        normalized_reset_stage1 <= normalized_reset_wire;
    end
    
    // ===== STAGE 3: Reset Processing =====
    always @(posedge clk) begin
        normalized_reset_stage2 <= normalized_reset_stage1;
    end
    
    // ===== STAGE 4: Vector Generation =====
    wire [WIDTH-1:0] reset_vector;
    
    // Generate reset vector based on enable and normalized reset
    assign reset_vector = enable_reg ? {WIDTH{normalized_reset_stage2}} : {WIDTH{1'b0}};
    
    always @(posedge clk) begin
        reset_out_internal <= reset_vector;
    end
    
    // ===== Output Assignment =====
    assign reset_out = reset_out_internal;
    
endmodule