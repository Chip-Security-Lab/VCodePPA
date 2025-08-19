//SystemVerilog
module basic_left_shift #(parameter DATA_WIDTH = 8) (
    input clk_i,
    input rst_i,
    input si,            // Serial input
    output so            // Serial output
);
    // Internal signals
    wire [DATA_WIDTH-1:0] shift_reg_data;
    
    // Instantiate the shift register controller
    shift_register_control #(
        .DATA_WIDTH(DATA_WIDTH)
    ) shift_reg_ctrl_inst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .si(si),
        .shift_reg_data(shift_reg_data)
    );
    
    // Instantiate the output handler
    output_handler #(
        .DATA_WIDTH(DATA_WIDTH)
    ) output_handler_inst (
        .shift_reg_data(shift_reg_data),
        .so(so)
    );
    
endmodule

// Shift register control module - handles the shifting operation
module shift_register_control #(parameter DATA_WIDTH = 8) (
    input clk_i,
    input rst_i,
    input si,
    output reg [DATA_WIDTH-1:0] shift_reg_data
);
    // Optimized reset and shift operation for better PPA
    always @(posedge clk_i) begin
        if (rst_i)
            shift_reg_data <= {DATA_WIDTH{1'b0}};
        else
            shift_reg_data <= {shift_reg_data[DATA_WIDTH-2:0], si};
    end
endmodule

// Output handler module - manages the serial output
module output_handler #(parameter DATA_WIDTH = 8) (
    input [DATA_WIDTH-1:0] shift_reg_data,
    output so
);
    // Direct assignment for the serial output bit
    assign so = shift_reg_data[DATA_WIDTH-1];
endmodule