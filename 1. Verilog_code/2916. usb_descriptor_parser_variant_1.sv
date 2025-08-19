//SystemVerilog
// Top-level module
module usb_descriptor_parser (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire start_parse,
    output wire [15:0] vendor_id,
    output wire [15:0] product_id,
    output wire [7:0] device_class,
    output wire [7:0] max_packet_size,
    output wire [7:0] num_configurations,
    output wire parsing_complete,
    output wire [2:0] parse_state
);
    // Interface signals between modules
    wire [7:0] desc_length;
    wire [7:0] desc_type;
    wire [7:0] byte_count;
    wire [7:0] field_position;
    wire state_idle, state_length, state_type, state_fields, state_complete;
    
    // Data pipeline signals
    wire [7:0] data_in_buffered;
    wire data_valid_buffered;
    
    // Input buffers for timing improvement
    input_buffer u_input_buffer (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_valid(data_valid),
        .data_out(data_in_buffered),
        .data_valid_out(data_valid_buffered)
    );

    // FSM Controller submodule
    parser_state_machine u_state_machine (
        .clk(clk),
        .reset(reset),
        .data_valid(data_valid_buffered),
        .start_parse(start_parse),
        .desc_length(desc_length),
        .byte_count(byte_count),
        .parse_state(parse_state),
        .state_idle(state_idle),
        .state_length(state_length),
        .state_type(state_type),
        .state_fields(state_fields),
        .state_complete(state_complete),
        .parsing_complete(parsing_complete)
    );

    // Byte counter module
    byte_counter u_byte_counter (
        .clk(clk),
        .reset(reset),
        .data_valid(data_valid_buffered),
        .state_idle(state_idle),
        .state_length(state_length),
        .state_type(state_type),
        .state_fields(state_fields),
        .byte_count(byte_count),
        .field_position(field_position)
    );

    // Descriptor metadata handler
    descriptor_metadata u_metadata (
        .clk(clk),
        .reset(reset),
        .data_in(data_in_buffered),
        .data_valid(data_valid_buffered),
        .state_idle(state_idle),
        .state_length(state_length),
        .desc_length(desc_length),
        .desc_type(desc_type)
    );

    // Device descriptor field extractor
    device_descriptor_fields u_device_fields (
        .clk(clk),
        .reset(reset),
        .data_in(data_in_buffered),
        .data_valid(data_valid_buffered),
        .state_fields(state_fields),
        .desc_type(desc_type),
        .field_position(field_position),
        .vendor_id(vendor_id),
        .product_id(product_id),
        .device_class(device_class),
        .max_packet_size(max_packet_size),
        .num_configurations(num_configurations)
    );

endmodule

// Input buffer module for timing improvement
module input_buffer (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire data_valid,
    output reg [7:0] data_out,
    output reg data_valid_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_out <= 8'h00;
            data_valid_out <= 1'b0;
        end else begin
            data_out <= data_in;
            data_valid_out <= data_valid;
        end
    end
endmodule

// Finite State Machine Controller
module parser_state_machine (
    input wire clk,
    input wire reset,
    input wire data_valid,
    input wire start_parse,
    input wire [7:0] desc_length,
    input wire [7:0] byte_count,
    output reg [2:0] parse_state,
    output wire state_idle,
    output wire state_length,
    output wire state_type,
    output wire state_fields,
    output wire state_complete,
    output reg parsing_complete
);
    // State definitions
    localparam IDLE = 3'd0;
    localparam LENGTH = 3'd1;
    localparam TYPE = 3'd2;
    localparam FIELDS = 3'd3;
    localparam COMPLETE = 3'd4;

    // Registered state flags for timing improvement
    reg [4:0] state_flags;
    assign {state_idle, state_length, state_type, state_fields, state_complete} = state_flags;

    // Next state logic separated from output logic
    reg [2:0] next_state;
    reg next_parsing_complete;
    
    // Length comparison pre-computation
    wire length_reached = (byte_count >= desc_length);

    // State transition logic - combinational
    always @(*) begin
        next_state = parse_state;
        next_parsing_complete = parsing_complete;
        
        case (parse_state)
            IDLE: begin
                if (start_parse && data_valid) begin
                    next_state = LENGTH;
                end
                next_parsing_complete = 1'b0;
            end
            
            LENGTH: begin
                if (data_valid) begin
                    next_state = TYPE;
                end
            end
            
            TYPE: begin
                if (data_valid) begin
                    next_state = FIELDS;
                end
            end
            
            FIELDS: begin
                if (length_reached) begin
                    next_state = COMPLETE;
                end
            end
            
            COMPLETE: begin
                next_parsing_complete = 1'b1;
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end

    // Sequential logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            parse_state <= IDLE;
            parsing_complete <= 1'b0;
            state_flags <= 5'b10000; // IDLE state active
        end else begin
            parse_state <= next_state;
            parsing_complete <= next_parsing_complete;
            
            // One-hot encoding for state flags (more timing efficient)
            case (next_state)
                IDLE:     state_flags <= 5'b10000;
                LENGTH:   state_flags <= 5'b01000;
                TYPE:     state_flags <= 5'b00100;
                FIELDS:   state_flags <= 5'b00010;
                COMPLETE: state_flags <= 5'b00001;
                default:  state_flags <= 5'b10000;
            endcase
        end
    end
endmodule

// Byte counter module
module byte_counter (
    input wire clk,
    input wire reset,
    input wire data_valid,
    input wire state_idle,
    input wire state_length,
    input wire state_type,
    input wire state_fields,
    output reg [7:0] byte_count,
    output reg [7:0] field_position
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            byte_count <= 8'd0;
            field_position <= 8'd0;
        end else begin
            if (state_idle && data_valid) begin
                byte_count <= 8'd1;
                field_position <= 8'd0;
            end else if (state_length && data_valid) begin
                byte_count <= 8'd2;
                field_position <= 8'd0;
            end else if (state_fields && data_valid) begin
                byte_count <= byte_count + 8'd1;
                field_position <= field_position + 8'd1;
            end
        end
    end
endmodule

// Descriptor metadata handler
module descriptor_metadata (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire state_idle,
    input wire state_length,
    output reg [7:0] desc_length,
    output reg [7:0] desc_type
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            desc_length <= 8'd0;
            desc_type <= 8'd0;
        end else begin
            if (state_idle && data_valid) begin
                desc_length <= data_in;
            end
            
            if (state_length && data_valid) begin
                desc_type <= data_in;
            end
        end
    end
endmodule

// Device descriptor field extractor
module device_descriptor_fields (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire state_fields,
    input wire [7:0] desc_type,
    input wire [7:0] field_position,
    output reg [15:0] vendor_id,
    output reg [15:0] product_id,
    output reg [7:0] device_class,
    output reg [7:0] max_packet_size,
    output reg [7:0] num_configurations
);
    // Field category for better decoding
    reg [3:0] field_category;
    reg device_desc_type;
    
    // Determine field category based on position
    always @(*) begin
        if (field_position <= 8'd0)
            field_category = 4'd0;
        else if (field_position <= 8'd5)
            field_category = 4'd1;
        else if (field_position <= 8'd7)
            field_category = 4'd2;
        else if (field_position <= 8'd9)
            field_category = 4'd3;
        else if (field_position <= 8'd16)
            field_category = 4'd4;
        else
            field_category = 4'd5;
    end
    
    // Update device descriptor type flag
    always @(posedge clk or posedge reset) begin
        if (reset)
            device_desc_type <= 1'b0;
        else
            device_desc_type <= (desc_type == 8'h01);
    end
    
    // Extract fields based on position
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            vendor_id <= 16'h0000;
            product_id <= 16'h0000;
            device_class <= 8'h00;
            max_packet_size <= 8'h00;
            num_configurations <= 8'h00;
        end else if (state_fields && data_valid && device_desc_type) begin
            case (field_category)
                4'd0: device_class <= data_in; // field_position == 0
                4'd1: begin // field_position 1-5
                    if (field_position == 8'd5) max_packet_size <= data_in;
                end
                4'd2: begin // field_position 6-7
                    if (field_position == 8'd6) vendor_id[7:0] <= data_in;
                    else vendor_id[15:8] <= data_in;
                end
                4'd3: begin // field_position 8-9
                    if (field_position == 8'd8) product_id[7:0] <= data_in;
                    else product_id[15:8] <= data_in;
                end
                4'd4: begin // field_position 10-16
                    if (field_position == 8'd16) num_configurations <= data_in;
                end
                default: ; // Do nothing
            endcase
        end
    end
endmodule