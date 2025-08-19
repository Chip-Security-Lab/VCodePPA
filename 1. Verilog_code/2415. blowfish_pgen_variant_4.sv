//SystemVerilog
module blowfish_pgen (
    input wire clk, 
    input wire init,
    input wire [31:0] key_segment,
    output reg [31:0] p_box_out
);
    localparam P_BOX_SIZE = 18;
    localparam P_INITIAL = 32'hB7E15163;
    localparam P_INCREMENT = 32'h9E3779B9;
    
    reg [31:0] p_box [0:P_BOX_SIZE-1];
    
    // 初始化P-box
    always @(posedge clk) begin
        if (init) begin
            p_box[0] <= P_INITIAL;
            p_box[1] <= P_INITIAL + P_INCREMENT;
            p_box[2] <= P_INITIAL + (P_INCREMENT << 1);
            p_box[3] <= P_INITIAL + (P_INCREMENT + (P_INCREMENT << 1));
            p_box[4] <= P_INITIAL + (P_INCREMENT << 2);
            p_box[5] <= P_INITIAL + (P_INCREMENT + (P_INCREMENT << 2));
            p_box[6] <= P_INITIAL + ((P_INCREMENT << 1) + (P_INCREMENT << 2));
            p_box[7] <= P_INITIAL + (P_INCREMENT + (P_INCREMENT << 1) + (P_INCREMENT << 2));
            p_box[8] <= P_INITIAL + (P_INCREMENT << 3);
            p_box[9] <= P_INITIAL + (P_INCREMENT + (P_INCREMENT << 3));
        end
    end
    
    // 初始化P-box续
    always @(posedge clk) begin
        if (init) begin
            p_box[10] <= P_INITIAL + ((P_INCREMENT << 1) + (P_INCREMENT << 3));
            p_box[11] <= P_INITIAL + (P_INCREMENT + (P_INCREMENT << 1) + (P_INCREMENT << 3));
            p_box[12] <= P_INITIAL + ((P_INCREMENT << 2) + (P_INCREMENT << 3));
            p_box[13] <= P_INITIAL + (P_INCREMENT + (P_INCREMENT << 2) + (P_INCREMENT << 3));
            p_box[14] <= P_INITIAL + ((P_INCREMENT << 1) + (P_INCREMENT << 2) + (P_INCREMENT << 3));
            p_box[15] <= P_INITIAL + (P_INCREMENT + (P_INCREMENT << 1) + (P_INCREMENT << 2) + (P_INCREMENT << 3));
            p_box[16] <= P_INITIAL + (P_INCREMENT << 4);
            p_box[17] <= P_INITIAL + (P_INCREMENT + (P_INCREMENT << 4));
        end
    end
    
    // 处理p_box[0]与key_segment的XOR操作
    always @(posedge clk) begin
        if (!init) begin
            p_box[0] <= p_box[0] ^ key_segment;
        end
    end
    
    // 处理p_box[1:8]的级联操作
    always @(posedge clk) begin
        if (!init) begin
            p_box[1] <= p_box[1] + {p_box[0][28:0], 3'b000};
            p_box[2] <= p_box[2] + {p_box[1][28:0], 3'b000};
            p_box[3] <= p_box[3] + {p_box[2][28:0], 3'b000};
            p_box[4] <= p_box[4] + {p_box[3][28:0], 3'b000};
            p_box[5] <= p_box[5] + {p_box[4][28:0], 3'b000};
            p_box[6] <= p_box[6] + {p_box[5][28:0], 3'b000};
            p_box[7] <= p_box[7] + {p_box[6][28:0], 3'b000};
            p_box[8] <= p_box[8] + {p_box[7][28:0], 3'b000};
        end
    end
    
    // 处理p_box[9:17]的级联操作
    always @(posedge clk) begin
        if (!init) begin
            p_box[9] <= p_box[9] + {p_box[8][28:0], 3'b000};
            p_box[10] <= p_box[10] + {p_box[9][28:0], 3'b000};
            p_box[11] <= p_box[11] + {p_box[10][28:0], 3'b000};
            p_box[12] <= p_box[12] + {p_box[11][28:0], 3'b000};
            p_box[13] <= p_box[13] + {p_box[12][28:0], 3'b000};
            p_box[14] <= p_box[14] + {p_box[13][28:0], 3'b000};
            p_box[15] <= p_box[15] + {p_box[14][28:0], 3'b000};
            p_box[16] <= p_box[16] + {p_box[15][28:0], 3'b000};
            p_box[17] <= p_box[17] + {p_box[16][28:0], 3'b000};
        end
    end
    
    // 更新输出
    always @(posedge clk) begin
        if (!init) begin
            p_box_out <= p_box[17];
        end
    end
    
endmodule