module cam_2_pipeline (
    input wire clk,
    input wire rst,         
    input wire write_en,    
    input wire [1:0] write_addr, 
    input wire [7:0] in_data,
    output reg [3:0] cam_address,
    output reg cam_valid
);
    reg [7:0] data0_stage1, data1_stage1, data2_stage1, data3_stage1;
    reg [7:0] data0_stage2, data1_stage2, data2_stage2, data3_stage2;
    reg cam_valid_stage1, cam_valid_stage2;
    reg [3:0] cam_address_stage1, cam_address_stage2;

    // Stage 1: Write Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data0_stage1 <= 8'b0;
            data1_stage1 <= 8'b0;
            data2_stage1 <= 8'b0;
            data3_stage1 <= 8'b0;
            cam_valid_stage1 <= 1'b0;
            cam_address_stage1 <= 4'h0;
        end else if (write_en) begin
            if (write_addr == 2'b00) begin
                data0_stage1 <= in_data;
            end else if (write_addr == 2'b01) begin
                data1_stage1 <= in_data;
            end else if (write_addr == 2'b10) begin
                data2_stage1 <= in_data;
            end else if (write_addr == 2'b11) begin
                data3_stage1 <= in_data;
            end
        end
    end

    // Stage 2: Match Logic - Already in if-else structure
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cam_valid_stage2 <= 1'b0;
            cam_address_stage2 <= 4'h0;
        end else begin
            if (data0_stage1 == in_data) begin
                cam_address_stage2 <= 4'h0;
                cam_valid_stage2 <= 1'b1;
            end else if (data1_stage1 == in_data) begin
                cam_address_stage2 <= 4'h1;
                cam_valid_stage2 <= 1'b1;
            end else if (data2_stage1 == in_data) begin
                cam_address_stage2 <= 4'h2;
                cam_valid_stage2 <= 1'b1;
            end else if (data3_stage1 == in_data) begin
                cam_address_stage2 <= 4'h3;
                cam_valid_stage2 <= 1'b1;
            end else begin
                cam_valid_stage2 <= 1'b0;
                cam_address_stage2 <= 4'h0;
            end
        end
    end

    // Stage 3: Output Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cam_address <= 4'h0;
            cam_valid <= 1'b0;
        end else begin
            cam_address <= cam_address_stage2;
            cam_valid <= cam_valid_stage2;
        end
    end
endmodule