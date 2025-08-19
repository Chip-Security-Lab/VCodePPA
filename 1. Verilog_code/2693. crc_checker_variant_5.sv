//SystemVerilog
module crc_calculator(
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire data_valid,
    output reg [7:0] crc_value
);
    parameter [7:0] POLY = 8'hD5;
    reg [7:0] shift_accumulator;
    reg [2:0] bit_counter;
    reg [7:0] temp_poly;
    
    always @(posedge clk) begin
        if (rst) begin
            crc_value <= 8'h00;
            shift_accumulator <= 8'h00;
            bit_counter <= 3'd0;
            temp_poly <= 8'h00;
        end else if (data_valid) begin
            if (bit_counter == 3'd0) begin
                shift_accumulator <= {crc_value[6:0], 1'b0};
                temp_poly <= (crc_value[7] ^ data_in[0]) ? POLY : 8'h00;
                bit_counter <= bit_counter + 1;
            end else if (bit_counter < 3'd7) begin
                shift_accumulator <= {shift_accumulator[6:0], 1'b0};
                temp_poly <= {temp_poly[6:0], 1'b0};
                bit_counter <= bit_counter + 1;
            end else begin
                crc_value <= shift_accumulator ^ temp_poly;
                bit_counter <= 3'd0;
            end
        end
    end
endmodule

module crc_comparator(
    input wire [7:0] calculated_crc,
    input wire [7:0] expected_crc,
    output reg crc_valid
);
    always @(*) begin
        crc_valid = (calculated_crc == expected_crc);
    end
endmodule

module crc_checker(
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire [7:0] crc_in,
    input wire data_valid,
    output wire crc_valid,
    output wire [7:0] calculated_crc
);
    
    wire [7:0] internal_crc;
    
    crc_calculator calc_inst(
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_valid(data_valid),
        .crc_value(internal_crc)
    );
    
    crc_comparator comp_inst(
        .calculated_crc(internal_crc),
        .expected_crc(crc_in),
        .crc_valid(crc_valid)
    );
    
    assign calculated_crc = internal_crc;
    
endmodule