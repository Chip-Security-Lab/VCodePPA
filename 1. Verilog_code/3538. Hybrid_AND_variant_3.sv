//SystemVerilog
module Hybrid_AND (
    // Clock and reset
    input  wire         aclk,
    input  wire         aresetn,
    
    // AXI-Stream Input interface
    input  wire [7:0]   s_axis_tdata,
    input  wire         s_axis_tvalid,
    input  wire [1:0]   s_axis_tuser,  // carries ctrl signal
    output wire         s_axis_tready,
    
    // AXI-Stream Output interface
    output wire [7:0]   m_axis_tdata,
    output wire         m_axis_tvalid,
    input  wire         m_axis_tready
);
    
    // Internal signals
    wire [7:0]  mask;
    wire [7:0]  result;
    
    // Input handshaking logic
    reg  input_data_valid;
    wire input_data_ready;
    reg  [7:0] base_reg;
    reg  [1:0] ctrl_reg;
    
    // Output handshaking logic
    reg  output_data_valid;
    wire output_data_ready;
    reg  [7:0] result_reg;
    
    // Input handshaking
    assign s_axis_tready = input_data_ready;
    assign input_data_ready = !input_data_valid || (output_data_valid && m_axis_tready);
    
    // Output handshaking
    assign m_axis_tvalid = output_data_valid;
    assign m_axis_tdata = result_reg;
    assign output_data_ready = m_axis_tready;
    
    // Input data capture
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            input_data_valid <= 1'b0;
            base_reg <= 8'h0;
            ctrl_reg <= 2'h0;
        end else if (input_data_ready && s_axis_tvalid) begin
            input_data_valid <= 1'b1;
            base_reg <= s_axis_tdata;
            ctrl_reg <= s_axis_tuser;
        end else if (input_data_valid && output_data_ready) begin
            input_data_valid <= 1'b0;
        end
    end
    
    // Output data update
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            output_data_valid <= 1'b0;
            result_reg <= 8'h0;
        end else if (input_data_valid && !output_data_valid) begin
            output_data_valid <= 1'b1;
            result_reg <= result;
        end else if (output_data_valid && output_data_ready) begin
            output_data_valid <= 1'b0;
        end
    end
    
    // Instantiate submodules
    MaskGenerator mask_gen (
        .ctrl(ctrl_reg),
        .mask(mask)
    );
    
    BitwiseOperation bit_op (
        .base(base_reg),
        .mask(mask),
        .result(result)
    );
    
endmodule

// Mask Generator module
module MaskGenerator(
    input  wire [1:0] ctrl,
    output wire [7:0] mask
);
    wire [3:0] shift_amount;
    
    // Calculate shift amount
    ShiftCalculator shift_calc (
        .ctrl(ctrl),
        .shift_amount(shift_amount)
    );
    
    // Generate mask (8'h0F << shift_amount)
    assign mask = 8'h0F << shift_amount;
    
endmodule

// Shift Calculator module
module ShiftCalculator(
    input  wire [1:0] ctrl,
    output wire [3:0] shift_amount
);
    // Calculate shift amount (ctrl * 4)
    assign shift_amount = {ctrl, 2'b00};  // Equivalent to multiplying by 4
    
endmodule

// Bitwise Operation module
module BitwiseOperation(
    input  wire [7:0] base,
    input  wire [7:0] mask,
    output wire [7:0] result
);
    // Perform AND operation
    assign result = base & mask;
    
endmodule