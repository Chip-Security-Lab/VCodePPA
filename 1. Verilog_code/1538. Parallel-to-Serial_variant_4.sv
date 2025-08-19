//SystemVerilog
// IEEE 1364-2005 Verilog
module p2s_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] parallel_in,
    input wire load_parallel,
    input wire shift_en,
    output wire serial_out,
    output wire [WIDTH-1:0] shadow_data
);
    // Pipeline stage registers
    reg [WIDTH-1:0] shift_reg_stage1;
    reg [WIDTH-1:0] shift_reg_stage2;
    reg [WIDTH-1:0] shadow_data_stage1;
    reg [WIDTH-1:0] shadow_data_stage2;
    
    // Control signals for pipeline stages
    reg load_stage1, load_stage2;
    reg shift_stage1, shift_stage2;
    
    // LUT-based operation control signals
    reg [2:0] op_select;
    reg [WIDTH-1:0] lut_output;
    
    // Pipeline stage 1 control signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_stage1 <= 1'b0;
            shift_stage1 <= 1'b0;
            op_select <= 3'b000;
        end else begin
            load_stage1 <= load_parallel;
            shift_stage1 <= shift_en;
            op_select <= {load_parallel, shift_en, shift_reg_stage1[WIDTH-1]};
        end
    end
    
    // Pipeline stage 2 control signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_stage2 <= 1'b0;
            shift_stage2 <= 1'b0;
        end else begin
            load_stage2 <= load_stage1;
            shift_stage2 <= shift_stage1;
        end
    end
    
    // LUT-based operation implementation
    always @(*) begin
        case (op_select)
            3'b100: lut_output = parallel_in; // Load parallel
            3'b010: lut_output = {shift_reg_stage1[WIDTH-2:0], 1'b0}; // Shift
            3'b110: lut_output = parallel_in; // Load parallel priority
            default: lut_output = shift_reg_stage1; // Hold value
        endcase
    end
    
    // Pipeline stage 1 - Data capture and LUT processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage1 <= {WIDTH{1'b0}};
            shadow_data_stage1 <= {WIDTH{1'b0}};
        end else begin
            // Input registration with LUT-based operation
            shift_reg_stage1 <= lut_output;
                
            // Shadow data registration
            if (load_parallel)
                shadow_data_stage1 <= parallel_in;
        end
    end
    
    // Pipeline stage 2 - Final processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage2 <= {WIDTH{1'b0}};
            shadow_data_stage2 <= {WIDTH{1'b0}};
        end else begin
            // Processing of shift register data using LUT
            if (load_stage1)
                shift_reg_stage2 <= shift_reg_stage1;
            else if (shift_stage1)
                shift_reg_stage2 <= {shift_reg_stage1[WIDTH-2:0], 1'b0};
            else
                shift_reg_stage2 <= shift_reg_stage1;
                
            // Shadow data forwarding
            if (load_stage1)
                shadow_data_stage2 <= shadow_data_stage1;
        end
    end
    
    // Output assignments
    assign serial_out = shift_reg_stage2[WIDTH-1];
    assign shadow_data = shadow_data_stage2;
    
endmodule