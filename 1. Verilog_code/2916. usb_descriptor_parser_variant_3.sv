//SystemVerilog
module usb_descriptor_parser(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire start_parse,
    output reg [15:0] vendor_id,
    output reg [15:0] product_id,
    output reg [7:0] device_class,
    output reg [7:0] max_packet_size,
    output reg [7:0] num_configurations,
    output reg parsing_complete,
    output reg [2:0] parse_state
);
    // State definitions using one-hot encoding
    localparam IDLE     = 5'b00001;
    localparam LENGTH   = 5'b00010;
    localparam TYPE     = 5'b00100;
    localparam FIELDS   = 5'b01000;
    localparam COMPLETE = 5'b10000;
    
    // Internal state register (one-hot encoded)
    reg [4:0] current_state;
    
    // State mapping for output compatibility
    always @(*) begin
        case (current_state)
            IDLE:     parse_state = 3'd0;
            LENGTH:   parse_state = 3'd1;
            TYPE:     parse_state = 3'd2;
            FIELDS:   parse_state = 3'd3;
            COMPLETE: parse_state = 3'd4;
            default:  parse_state = 3'd0;
        endcase
    end
    
    // Registered input signals for forward retiming
    reg [7:0] data_in_reg;
    reg data_valid_reg;
    reg start_parse_reg;
    
    // Internal registers
    reg [7:0] desc_length;
    reg [7:0] desc_type;
    reg [7:0] byte_count;
    reg [7:0] field_position;
    
    // Register input signals
    always @(posedge clk) begin
        data_in_reg <= data_in;
        data_valid_reg <= data_valid;
        start_parse_reg <= start_parse;
    end
    
    // Main state machine with registered inputs and one-hot encoding
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
            vendor_id <= 16'h0000;
            product_id <= 16'h0000;
            device_class <= 8'h00;
            max_packet_size <= 8'h00;
            num_configurations <= 8'h00;
            parsing_complete <= 1'b0;
            byte_count <= 8'd0;
            field_position <= 8'd0;
        end else begin
            case (current_state)
                IDLE: begin
                    if (start_parse_reg && data_valid_reg) begin
                        desc_length <= data_in_reg;
                        current_state <= LENGTH;
                        byte_count <= 8'd1;
                    end
                    parsing_complete <= 1'b0;
                end
                LENGTH: begin
                    if (data_valid_reg) begin
                        desc_type <= data_in_reg;
                        byte_count <= 8'd2;
                        field_position <= 8'd0;
                        current_state <= TYPE;
                    end
                end
                // Additional states would be implemented here...
                default: current_state <= IDLE;
            endcase
        end
    end
endmodule