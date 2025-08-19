//SystemVerilog
///////////////////////////////////////////////////////////
// Filename: priority_load_reg_top.v
// Top level module for priority-based load register
///////////////////////////////////////////////////////////

module priority_load_reg(
    input clk, rst_n,
    input [7:0] data_a, data_b, data_c,
    input load_a, load_b, load_c,
    output [7:0] result
);

    // Internal signals
    wire [7:0] selected_data;
    wire valid_load;

    // Priority selector submodule
    priority_selector u_priority_selector(
        .data_a(data_a),
        .data_b(data_b), 
        .data_c(data_c),
        .load_a(load_a), 
        .load_b(load_b), 
        .load_c(load_c),
        .selected_data(selected_data),
        .valid_load(valid_load)
    );

    // Register unit submodule
    register_unit u_register_unit(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(selected_data),
        .load_en(valid_load),
        .data_out(result)
    );

endmodule

///////////////////////////////////////////////////////////
// Priority selector module - determines which data input
// to select based on priority rules
///////////////////////////////////////////////////////////

module priority_selector(
    input [7:0] data_a, data_b, data_c,
    input load_a, load_b, load_c,
    output reg [7:0] selected_data,
    output wire valid_load
);

    // Optimized priority encoding using one-hot encoding
    reg [2:0] select_vector;
    
    // Convert priority to one-hot encoding for better synthesis
    always @(*) begin
        casez ({load_a, load_b, load_c})
            3'b1??: select_vector = 3'b100; // A has highest priority
            3'b01?: select_vector = 3'b010; // B has medium priority
            3'b001: select_vector = 3'b001; // C has lowest priority
            default: select_vector = 3'b000;
        endcase
    end
    
    // Data selection using optimized multiplexing logic
    always @(*) begin
        case (select_vector)
            3'b100: selected_data = data_a;
            3'b010: selected_data = data_b;
            3'b001: selected_data = data_c;
            default: selected_data = 8'h00;
        endcase
    end
    
    // Generate valid_load signal - OR reduction is more efficient
    assign valid_load = |{load_a, load_b, load_c};

endmodule

///////////////////////////////////////////////////////////
// Register unit module - stores the selected data
// on positive clock edge when enabled
///////////////////////////////////////////////////////////

module register_unit(
    input clk, rst_n,
    input [7:0] data_in,
    input load_en,
    output reg [7:0] data_out
);

    // Register with asynchronous reset and clock enable
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 8'h00;
        else if (load_en)
            data_out <= data_in;
    end

endmodule