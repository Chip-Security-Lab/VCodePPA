//SystemVerilog
// SystemVerilog
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
    // Pipeline stage definitions
    localparam IDLE = 3'd0;
    localparam LENGTH = 3'd1;
    localparam TYPE = 3'd2;
    localparam FIELDS = 3'd3;
    localparam COMPLETE = 3'd4;
    
    // Data path registers
    reg [7:0] desc_length_stage1, desc_length_stage2;
    reg [7:0] desc_type_stage1, desc_type_stage2;
    reg [7:0] byte_count_stage1, byte_count_stage2;
    reg [7:0] field_position_stage1, field_position_stage2;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2;
    reg flush_pipeline;
    
    // Instantiate the stage1 pipeline processor
    stage1_processor stage1_proc(
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_valid(data_valid),
        .start_parse(start_parse),
        .parse_state(parse_state),
        .desc_length(desc_length_stage1),
        .desc_type(desc_type_stage1),
        .byte_count(byte_count_stage1),
        .field_position(field_position_stage1),
        .valid_out(valid_stage1),
        .flush_pipeline(flush_pipeline)
    );
    
    // Instantiate the pipeline register stage
    pipeline_register pipeline_reg(
        .clk(clk),
        .reset(reset),
        .desc_length_in(desc_length_stage1),
        .desc_type_in(desc_type_stage1),
        .byte_count_in(byte_count_stage1),
        .field_position_in(field_position_stage1),
        .valid_in(valid_stage1),
        .desc_length_out(desc_length_stage2),
        .desc_type_out(desc_type_stage2),
        .byte_count_out(byte_count_stage2),
        .field_position_out(field_position_stage2),
        .valid_out(valid_stage2)
    );
    
    // Instantiate the stage3 output processor
    output_processor stage3_proc(
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .valid_in(valid_stage2),
        .desc_type(desc_type_stage2),
        .field_position(field_position_stage2),
        .flush_pipeline(flush_pipeline),
        .parse_state(parse_state),
        .vendor_id(vendor_id),
        .product_id(product_id),
        .device_class(device_class),
        .max_packet_size(max_packet_size),
        .num_configurations(num_configurations),
        .parsing_complete(parsing_complete)
    );
endmodule

// Stage 1: Input and Initial Parsing Module
module stage1_processor(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire start_parse,
    output reg [2:0] parse_state,
    output reg [7:0] desc_length,
    output reg [7:0] desc_type,
    output reg [7:0] byte_count,
    output reg [7:0] field_position,
    output reg valid_out,
    output reg flush_pipeline
);
    // Pipeline stage definitions
    localparam IDLE = 3'd0;
    localparam LENGTH = 3'd1;
    localparam TYPE = 3'd2;
    localparam FIELDS = 3'd3;
    localparam COMPLETE = 3'd4;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            parse_state <= IDLE;
            byte_count <= 8'd0;
            field_position <= 8'd0;
            valid_out <= 1'b0;
            flush_pipeline <= 1'b0;
            desc_length <= 8'd0;
            desc_type <= 8'd0;
        end else begin
            case (parse_state)
                IDLE: begin
                    if (start_parse && data_valid) begin
                        desc_length <= data_in;
                        parse_state <= LENGTH;
                        byte_count <= 8'd1;
                        valid_out <= 1'b1;
                    end else begin
                        valid_out <= 1'b0;
                    end
                    flush_pipeline <= 1'b0;
                end
                
                LENGTH: begin
                    if (data_valid) begin
                        desc_type <= data_in;
                        byte_count <= 8'd2;
                        field_position <= 8'd0;
                        parse_state <= TYPE;
                        valid_out <= 1'b1;
                    end else begin
                        valid_out <= 1'b0;
                    end
                end
                
                TYPE: begin
                    if (data_valid) begin
                        // Process the type data
                        valid_out <= 1'b1;
                        parse_state <= FIELDS;
                        field_position <= field_position + 8'd1;
                        byte_count <= byte_count + 8'd1;
                    end else begin
                        valid_out <= 1'b0;
                    end
                end
                
                FIELDS: begin
                    if (data_valid) begin
                        byte_count <= byte_count + 8'd1;
                        field_position <= field_position + 8'd1;
                        valid_out <= 1'b1;
                        
                        if (byte_count >= desc_length - 8'd1) begin
                            parse_state <= COMPLETE;
                            flush_pipeline <= 1'b1;
                        end
                    end else begin
                        valid_out <= 1'b0;
                    end
                end
                
                COMPLETE: begin
                    parse_state <= IDLE;
                    valid_out <= 1'b0;
                    flush_pipeline <= 1'b0;
                end
                
                default: begin
                    parse_state <= IDLE;
                    valid_out <= 1'b0;
                end
            endcase
        end
    end
endmodule

// Pipeline Register Module
module pipeline_register(
    input wire clk,
    input wire reset,
    input wire [7:0] desc_length_in,
    input wire [7:0] desc_type_in,
    input wire [7:0] byte_count_in,
    input wire [7:0] field_position_in,
    input wire valid_in,
    output reg [7:0] desc_length_out,
    output reg [7:0] desc_type_out,
    output reg [7:0] byte_count_out,
    output reg [7:0] field_position_out,
    output reg valid_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            desc_length_out <= 8'd0;
            desc_type_out <= 8'd0;
            byte_count_out <= 8'd0;
            field_position_out <= 8'd0;
            valid_out <= 1'b0;
        end else begin
            // Pipeline register transfers
            desc_length_out <= desc_length_in;
            desc_type_out <= desc_type_in;
            byte_count_out <= byte_count_in;
            field_position_out <= field_position_in;
            valid_out <= valid_in;
        end
    end
endmodule

// Output Processing Module
module output_processor(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire valid_in,
    input wire [7:0] desc_type,
    input wire [7:0] field_position,
    input wire flush_pipeline,
    input wire [2:0] parse_state,
    output reg [15:0] vendor_id,
    output reg [15:0] product_id,
    output reg [7:0] device_class,
    output reg [7:0] max_packet_size,
    output reg [7:0] num_configurations,
    output reg parsing_complete
);
    // Pipeline stage definitions
    localparam IDLE = 3'd0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            vendor_id <= 16'h0000;
            product_id <= 16'h0000;
            device_class <= 8'h00;
            max_packet_size <= 8'h00;
            num_configurations <= 8'h00;
            parsing_complete <= 1'b0;
        end else begin
            if (valid_in) begin
                if (desc_type == 8'h01) begin  // Device descriptor
                    case (field_position)
                        8'd2: device_class <= data_in;
                        8'd7: max_packet_size <= data_in;
                        8'd8: vendor_id[7:0] <= data_in;
                        8'd9: vendor_id[15:8] <= data_in;
                        8'd10: product_id[7:0] <= data_in;
                        8'd11: product_id[15:8] <= data_in;
                        8'd17: num_configurations <= data_in;
                        default: ; // No operation for other positions
                    endcase
                end
            end
            
            // Set completion signal on flush
            if (flush_pipeline) begin
                parsing_complete <= 1'b1;
            end else if (parse_state == IDLE) begin
                parsing_complete <= 1'b0;
            end
        end
    end
endmodule