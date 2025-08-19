module i2c_tristate_slave(
    input clk_i, rst_i,
    input [6:0] addr_i,
    output reg [7:0] data_o,
    output reg valid_o,
    inout sda_io, scl_io
);
    reg sda_oe, sda_o, scl_oe, scl_o;
    reg [2:0] state_r;
    reg [7:0] shift_r;
    reg [2:0] bit_cnt;
    
    // 添加缺失的start_detected信号
    reg start_detected;
    
    // 三态控制
    assign sda_io = sda_oe ? 1'bz : sda_o;
    assign scl_io = scl_oe ? 1'bz : scl_o;
    
    wire sda_i = sda_io;
    wire scl_i = scl_io;
    
    // 起始条件检测
    always @(posedge clk_i) begin
        if (scl_i && sda_i && !sda_o)
            start_detected <= 1'b1;
        else
            start_detected <= 1'b0;
    end
    
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            state_r <= 3'b000;
            sda_oe <= 1'b1; scl_oe <= 1'b1;
            data_o <= 8'h00;
            valid_o <= 1'b0;
        end else case(state_r)
            3'b000: if (start_detected) begin
                state_r <= 3'b001;
                bit_cnt <= 3'b000;
            end
            3'b001: if (bit_cnt == 3'b111) begin
                state_r <= 3'b010;
                if (shift_r[7:1] == addr_i)
                    sda_oe <= 1'b0; // ACK
            end else if (scl_i) begin
                shift_r <= {shift_r[6:0], sda_i};
                bit_cnt <= bit_cnt + 1;
            end
            3'b010: begin
                state_r <= 3'b011;
                sda_oe <= 1'b1;
            end
            3'b011: if (bit_cnt == 3'b111) begin
                state_r <= 3'b100;
                data_o <= shift_r;
                valid_o <= 1'b1;
            end else if (scl_i) begin
                shift_r <= {shift_r[6:0], sda_i};
                bit_cnt <= bit_cnt + 1;
            end
            3'b100: begin
                state_r <= 3'b000;
                valid_o <= 1'b0;
            end
            default: state_r <= 3'b000;
        endcase
    end
endmodule