//SystemVerilog
module multi_waveform(
    input clk,
    input rst_n,
    input [1:0] wave_sel,
    output reg [7:0] wave_out
);

    wire [7:0] square_wave;
    wire [7:0] sawtooth_wave;
    wire [7:0] triangle_wave;
    wire [7:0] staircase_wave;

    square_wave_gen square_inst(
        .clk(clk),
        .rst_n(rst_n),
        .wave_out(square_wave)
    );

    sawtooth_wave_gen sawtooth_inst(
        .clk(clk),
        .rst_n(rst_n),
        .wave_out(sawtooth_wave)
    );

    triangle_wave_gen triangle_inst(
        .clk(clk),
        .rst_n(rst_n),
        .wave_out(triangle_wave)
    );

    staircase_wave_gen staircase_inst(
        .clk(clk),
        .rst_n(rst_n),
        .wave_out(staircase_wave)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wave_out <= 8'd0;
        end else begin
            case (wave_sel)
                2'b00: wave_out <= square_wave;
                2'b01: wave_out <= sawtooth_wave;
                2'b10: wave_out <= triangle_wave;
                2'b11: wave_out <= staircase_wave;
            endcase
        end
    end

endmodule

module square_wave_gen(
    input clk,
    input rst_n,
    output reg [7:0] wave_out
);
    reg [7:0] counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 8'd0;
            wave_out <= 8'd0;
        end else begin
            counter <= counter + 8'd1;
            wave_out <= (counter < 8'd128) ? 8'd255 : 8'd0;
        end
    end
endmodule

module sawtooth_wave_gen(
    input clk,
    input rst_n,
    output reg [7:0] wave_out
);
    reg [7:0] counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 8'd0;
            wave_out <= 8'd0;
        end else begin
            counter <= counter + 8'd1;
            wave_out <= counter;
        end
    end
endmodule

module triangle_wave_gen(
    input clk,
    input rst_n,
    output reg [7:0] wave_out
);
    reg [7:0] counter;
    reg direction;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 8'd0;
            direction <= 1'b0;
            wave_out <= 8'd0;
        end else begin
            counter <= counter + 8'd1;
            
            if (!direction) begin
                if (counter == 8'd255) direction <= 1'b1;
                wave_out <= counter;
            end else begin
                if (counter == 8'd0) direction <= 1'b0;
                wave_out <= 8'd255 - counter;
            end
        end
    end
endmodule

module staircase_wave_gen(
    input clk,
    input rst_n,
    output reg [7:0] wave_out
);
    reg [7:0] counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 8'd0;
            wave_out <= 8'd0;
        end else begin
            counter <= counter + 8'd1;
            wave_out <= {counter[7:2], 2'b00};
        end
    end
endmodule