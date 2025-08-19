//SystemVerilog
// SystemVerilog
// Data storage module with separated combinational and sequential logic
module data_storage (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    output wire [7:0] stored_data
);
    reg [7:0] stored_data_reg;
    
    // Sequential logic
    always @(posedge clk) begin
        if (rst)
            stored_data_reg <= 8'b0;
        else
            stored_data_reg <= data_in;
    end
    
    // Combinational logic
    assign stored_data = stored_data_reg;
endmodule

// Comparison module (pure combinational logic)
module data_comparator (
    input wire [7:0] stored_data,
    input wire [7:0] data_in,
    output wire match_flag
);
    // Pure combinational logic
    assign match_flag = (stored_data == data_in);
endmodule

// State control module with separated combinational and sequential logic
module state_controller (
    input wire clk,
    input wire rst,
    output wire [1:0] state
);
    // State definition
    localparam IDLE = 2'b00,
              COMPARE = 2'b01;
    
    reg [1:0] state_reg;
    reg [1:0] next_state;
    
    // Sequential logic
    always @(posedge clk) begin
        if (rst)
            state_reg <= IDLE;
        else
            state_reg <= next_state;
    end
    
    // Combinational logic for next state calculation
    always @(*) begin
        case (state_reg)
            IDLE: next_state = COMPARE;
            COMPARE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // Output assignment
    assign state = state_reg;
endmodule

// Top-level module
module cam_9 (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    output wire match_flag,
    output wire [7:0] stored_data
);
    wire [1:0] state;
    
    // Instantiate submodules
    data_storage storage_unit (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .stored_data(stored_data)
    );
    
    data_comparator comparator_unit (
        .stored_data(stored_data),
        .data_in(data_in),
        .match_flag(match_flag)
    );
    
    state_controller controller_unit (
        .clk(clk),
        .rst(rst),
        .state(state)
    );
endmodule